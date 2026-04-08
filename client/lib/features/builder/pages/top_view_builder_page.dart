import 'package:client/core/models/auth_session.dart';
import 'package:flutter/material.dart';

class TopViewBuilderPage extends StatefulWidget {
  final AuthSession session;

  const TopViewBuilderPage({
    super.key,
    required this.session,
  });

  @override
  State<TopViewBuilderPage> createState() => _TopViewBuilderPageState();
}

class _TopViewBuilderPageState extends State<TopViewBuilderPage> {
  static const double _leftPanelWidth = 280;
  static const int _cols = 26;
  static const int _rows = 20;
  static const double _editorFontSize = 18;
  static const double _editorLineHeight = 1.45;
  static const StrutStyle _editorStrutStyle = StrutStyle(
    fontFamily: 'monospace',
    fontSize: _editorFontSize,
    height: _editorLineHeight,
    forceStrutHeight: true,
  );

  final Map<_Cell, _BoardItemType> _items = <_Cell, _BoardItemType>{};
  final List<_CodeBlock> _allowedBlocks = <_CodeBlock>[];
  late final TextEditingController _titleController;
  late final TextEditingController _codeController;
  late final ScrollController _codeScrollController;
  late final ScrollController _lineNumberScrollController;
  late final FocusNode _codeFocusNode;

  String _status =
      'Drag pieces onto the grid, drag solution blocks into the tray, or use the left presets to write code.';
  bool _rulerActive = false;
  bool _isBoardItemDragging = false;
  bool _isSolutionTrayBlockDragging = false;
  _Cell? _rulerStart;
  _Cell? _rulerHoverCell;
  Offset? _rulerHoverPosition;
  int? _previewDistance;
  int? _lastDistance;
  Offset? _lastDistancePosition;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'New Level');
    _codeController = TextEditingController();
    _codeScrollController = ScrollController()..addListener(_syncLineNumberScroll);
    _lineNumberScrollController = ScrollController();
    _codeFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _codeScrollController
      ..removeListener(_syncLineNumberScroll)
      ..dispose();
    _lineNumberScrollController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _syncLineNumberScroll() {
    if (!_lineNumberScrollController.hasClients || !_codeScrollController.hasClients) {
      return;
    }

    final targetOffset = _codeScrollController.offset.clamp(
      0.0,
      _lineNumberScrollController.position.maxScrollExtent,
    );
    if ((_lineNumberScrollController.offset - targetOffset).abs() < 0.5) {
      return;
    }

    _lineNumberScrollController.jumpTo(targetOffset);
  }

  void _insertBlock(_CodeBlock block) {
    final value = _codeController.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final start = selection.start;
    final end = selection.end;
    final insertedText = _buildInsertedCode(
      fullText: value.text,
      selectionStart: start,
      block: block,
    );
    final text = value.text.replaceRange(
      start,
      end,
      insertedText,
    );
    _codeController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: start + insertedText.length,
      ),
    );
    _codeFocusNode.requestFocus();
  }

  String _buildInsertedCode({
    required String fullText,
    required int selectionStart,
    required _CodeBlock block,
  }) {
    final shouldStartOnNewLine =
        block.startsOnNewLine &&
        selectionStart > 0 &&
        !fullText.substring(0, selectionStart).endsWith('\n');
    final prefix = shouldStartOnNewLine ? '\n' : '';
    return '$prefix${block.insertText}';
  }

  void _clearCode() {
    setState(() {
      _codeController.clear();
      _status = 'Code editor cleared.';
    });
  }

  void _handleSavePressed() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Top view saving will be connected next.'),
        backgroundColor: Colors.blueGrey.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _acceptsBoardPayload(_Payload? payload) {
    if (payload == null) {
      return false;
    }
    return payload.kind == _PayloadKind.boardPalette ||
        payload.kind == _PayloadKind.boardItem ||
        payload.kind == _PayloadKind.ruler;
  }

  void _handleBoardDrop(_Payload payload, _Cell target) {
    switch (payload.kind) {
      case _PayloadKind.boardPalette:
        if (payload.itemType != null) {
          _placeItem(payload.itemType!, target);
        }
      case _PayloadKind.boardItem:
        if (payload.itemType != null && payload.sourceCell != null) {
          _placeItem(payload.itemType!, target, source: payload.sourceCell);
        }
      case _PayloadKind.ruler:
        _activateRuler();
      case _PayloadKind.solutionBlock:
      case _PayloadKind.solutionTrayBlock:
        return;
    }
  }

  void _placeItem(_BoardItemType type, _Cell target, {_Cell? source}) {
    if (source == target && _items[target] == type) {
      return;
    }
    setState(() {
      if (source != null) {
        _items.remove(source);
      }
      if (type == _BoardItemType.player || type == _BoardItemType.goal) {
        _items.removeWhere((cell, item) => item == type && cell != target);
      }
      _items[target] = type;
      _status = source == null
          ? 'Placed ${type.label}.'
          : 'Moved ${type.label} to a new tile.';
    });
  }

  void _deleteItem(_Cell cell) {
    final removed = _items[cell];
    if (removed == null) {
      return;
    }
    setState(() {
      _items.remove(cell);
      _status = 'Deleted ${removed.label}.';
    });
  }

  void _deleteSolutionBlock(_CodeBlock block) {
    setState(() {
      _allowedBlocks.removeWhere((item) => item.id == block.id);
      _status = 'Deleted ${block.label} from the solution tray.';
    });
  }

  void _activateRuler() {
    setState(() {
      _rulerActive = true;
      _rulerStart = null;
      _rulerHoverCell = null;
      _rulerHoverPosition = null;
      _previewDistance = null;
      _lastDistance = null;
      _lastDistancePosition = null;
      _status = 'Ruler ready. Click the first point, then click a second point.';
    });
  }

  void _clearRuler() {
    setState(() {
      _rulerActive = false;
      _rulerStart = null;
      _rulerHoverCell = null;
      _rulerHoverPosition = null;
      _previewDistance = null;
      _lastDistance = null;
      _lastDistancePosition = null;
      _status = 'Ruler cleared.';
    });
  }

  void _tapCell(_Cell cell, Offset boardPosition) {
    if (!_rulerActive) {
      return;
    }
    if (_rulerStart == null) {
      setState(() {
        _rulerStart = cell;
        _previewDistance = null;
        _lastDistance = null;
        _lastDistancePosition = null;
        _status = 'First point selected. Click another tile or object.';
      });
      return;
    }
    final distance = _distanceBetween(_rulerStart!, cell);
    setState(() {
      _rulerStart = null;
      _rulerHoverCell = null;
      _rulerHoverPosition = null;
      _previewDistance = null;
      _lastDistance = distance;
      _lastDistancePosition = boardPosition;
      _status = 'Measured $distance grid squares.';
    });
  }

  void _hoverCell(_Cell cell, Offset boardPosition) {
    if (!_rulerActive || _rulerStart == null) {
      return;
    }
    setState(() {
      _rulerHoverCell = cell;
      _rulerHoverPosition = boardPosition;
      _previewDistance = _distanceBetween(_rulerStart!, cell);
    });
  }

  void _leaveBoard() {
    if (_rulerHoverCell == null &&
        _rulerHoverPosition == null &&
        _previewDistance == null) {
      return;
    }
    setState(() {
      _rulerHoverCell = null;
      _rulerHoverPosition = null;
      _previewDistance = null;
    });
  }

  int _distanceBetween(_Cell a, _Cell b) {
    return (a.column - b.column).abs() + (a.row - b.row).abs();
  }

  void _addAllowedBlock(_CodeBlock block) {
    if (_allowedBlocks.any((item) => item.id == block.id)) {
      setState(() {
        _status = '${block.label} is already in the solution tray.';
      });
      return;
    }
    setState(() {
      _allowedBlocks.add(block);
      _status = 'Added ${block.label} to the solution tray.';
    });
  }

  void _removeAllowedBlock(_CodeBlock block) {
    setState(() {
      _allowedBlocks.removeWhere((item) => item.id == block.id);
      _status = 'Removed ${block.label} from the solution tray.';
    });
  }

  Future<void> _handleClearLevelPressed() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Level?'),
          content: const Text(
            'This will remove all placed pieces, solution blocks, and editor code.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldClear != true) {
      return;
    }

    setState(() {
      _items.clear();
      _allowedBlocks.clear();
      _codeController.clear();
      _rulerActive = false;
      _rulerStart = null;
      _rulerHoverCell = null;
      _rulerHoverPosition = null;
      _previewDistance = null;
      _lastDistance = null;
      _lastDistancePosition = null;
      _status = 'Level cleared.';
    });
  }

  Offset _boardOffset(
    _Cell cell,
    Offset localPosition,
    double cellWidth,
    double cellHeight,
  ) {
    return Offset(
      cell.column * cellWidth + localPosition.dx,
      cell.row * cellHeight + localPosition.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'New Level',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.titleLarge,
          cursorColor: Colors.black,
          maxLines: 1,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: _handleSavePressed,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFEAF6FF),
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1280;
                final tools = _buildToolsSidebar();
                final grid = _buildGridPanel();
                final editor = _buildCodeWorkspace();

                if (compact) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 520, child: tools),
                        const SizedBox(height: 20),
                        SizedBox(height: 700, child: grid),
                        const SizedBox(height: 20),
                        SizedBox(height: 760, child: editor),
                      ],
                    ),
                  );
                }

                return Row(
                  children: [
                    Container(
                      width: _leftPanelWidth,
                      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        border: Border(
                          right: BorderSide(color: Colors.blueGrey.shade100),
                        ),
                      ),
                      child: tools,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 13, child: grid),
                            const SizedBox(width: 20),
                            Expanded(flex: 7, child: editor),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(child: _buildTrash()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsSidebar() {
    return ListView(
      children: [
        _buildSidebarSection(
          title: 'Tools',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _BoardItemType.values.map(_buildBoardPaletteItem).toList(),
          ),
        ),
        const SizedBox(height: 14),
        _buildSidebarSection(
          title: 'Instructions',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _codeBlocks.map(_buildInstructionTool).toList(),
          ),
        ),
        const SizedBox(height: 14),
        _buildSidebarSection(
          title: 'Level Actions',
          child: FilledButton.icon(
            onPressed: _handleClearLevelPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.layers_clear_outlined, size: 18),
            label: const Text(
              'Clear Level',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildSidebarSection(
          title: 'Level Info',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grid: $_cols columns x $_rows rows',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _rulerActive
                    ? 'Ruler mode is active. Pick two tiles to measure.'
                    : 'Drag pieces into the board, then write the path in the code panel.',
                style: TextStyle(
                  color: Colors.blueGrey.shade700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridPanel() {
    return _windowFrame(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_rulerActive) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _clearRuler,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      'Clear Ruler',
                      style: TextStyle(
                        color: Colors.blueGrey.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: _cols / _rows,
                  child: _buildBoard(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / _cols;
        final cellHeight = constraints.maxHeight / _rows;
        return MouseRegion(
          onExit: (_) => _leaveBoard(),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFCADDF0),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.blueGrey.shade200, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cols * _rows,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _cols,
                  ),
                  itemBuilder: (context, index) {
                    final row = index ~/ _cols;
                    final column = index % _cols;
                    final cell = _Cell(column: column, row: row);
                    final item = _items[cell];
                    return DragTarget<_Payload>(
                      onWillAcceptWithDetails: (details) {
                        return _acceptsBoardPayload(details.data);
                      },
                      onAcceptWithDetails: (details) {
                        _handleBoardDrop(details.data, cell);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final highlight = candidateData.any(_acceptsBoardPayload);
                        final rulerStart = _rulerStart == cell;
                        final rulerHover = _rulerHoverCell == cell;
                        return MouseRegion(
                          onHover: (event) {
                            _hoverCell(
                              cell,
                              _boardOffset(
                                cell,
                                event.localPosition,
                                cellWidth,
                                cellHeight,
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: rulerStart
                                  ? const Color(0xFFDCFCE7)
                                  : rulerHover
                                  ? const Color(0xFFDFF3FF)
                                  : highlight
                                  ? const Color(0xFFE8F4FF)
                                  : item == _BoardItemType.obstacle
                                  ? const Color(0xFFDCE4EC)
                                  : const Color(0xFFCFE1F3),
                              border: Border.all(
                                color: rulerStart
                                    ? const Color(0xFF33A167)
                                    : rulerHover
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFA7C4DE),
                                width: rulerStart || rulerHover ? 2 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapUp: (details) {
                                      _tapCell(
                                        cell,
                                        _boardOffset(
                                          cell,
                                          details.localPosition,
                                          cellWidth,
                                          cellHeight,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (item != null)
                                  Positioned.fill(
                                    child: Center(
                                      child: Draggable<_Payload>(
                                        data: _Payload.boardItem(item, cell),
                                        feedback: Material(
                                          color: Colors.transparent,
                                          child: _boardIcon(item, small: true),
                                        ),
                                        childWhenDragging:
                                            const SizedBox.expand(),
                                        onDragStarted: () {
                                          setState(() {
                                            _isBoardItemDragging = true;
                                          });
                                        },
                                        onDragEnd: (_) {
                                          if (!mounted) {
                                            return;
                                          }
                                          setState(() {
                                            _isBoardItemDragging = false;
                                          });
                                        },
                                        child: _boardIcon(item),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                Positioned(top: 10, left: 10, child: _buildRulerHandle()),
                if (_previewDistance != null &&
                    _rulerHoverPosition != null &&
                    _rulerStart != null)
                  _distanceBubble(
                    position: _rulerHoverPosition!,
                    distance: _previewDistance!,
                    preview: true,
                  ),
                if (_lastDistance != null && _lastDistancePosition != null)
                  _distanceBubble(
                    position: _lastDistancePosition!,
                    distance: _lastDistance!,
                    preview: false,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCodeWorkspace() {
    return _windowFrame(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: _clearCode,
                  child: Text(
                    'Clear',
                    style: TextStyle(color: Colors.blueGrey.shade900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blueGrey.shade200, width: 2),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 42,
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _codeController,
                        builder: (context, value, child) {
                          final lineCount = '\n'.allMatches(value.text).length + 1;
                          return SingleChildScrollView(
                            controller: _lineNumberScrollController,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List<Widget>.generate(lineCount, (index) {
                                  return Text(
                                    '${index + 1}',
                                    strutStyle: _editorStrutStyle,
                                    style: TextStyle(
                                      color: Colors.blueGrey.shade400,
                                      fontFamily: 'monospace',
                                      fontSize: _editorFontSize,
                                      height: _editorLineHeight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        focusNode: _codeFocusNode,
                        scrollController: _codeScrollController,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        strutStyle: _editorStrutStyle,
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'monospace',
                          fontSize: _editorFontSize,
                          height: _editorLineHeight,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          hintText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Solution Blocks',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.blueGrey.shade900,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildSolutionTray(),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionTray() {
    return DragTarget<_Payload>(
      onWillAcceptWithDetails: (details) {
        return details.data.kind == _PayloadKind.solutionBlock;
      },
      onAcceptWithDetails: (details) {
        if (details.data.block != null) {
          _addAllowedBlock(details.data.block!);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final highlight = candidateData.any(
          (data) => data?.kind == _PayloadKind.solutionBlock,
        );

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: highlight ? Colors.green.shade50 : Colors.blueGrey.shade50,
            border: Border.all(
              color: highlight ? Colors.green.shade300 : Colors.blueGrey.shade200,
              width: highlight ? 2.4 : 1.8,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: _allowedBlocks.isEmpty
              ? Center(
                  child: Text(
                    'Drop instruction blocks here',
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _allowedBlocks.map(_allowedChip).toList(),
                ),
        );
      },
    );
  }

  Widget _buildBoardPaletteItem(_BoardItemType item) {
    final tile = _toolTile(
      label: item.label,
      icon: item.icon,
      color: item.color,
    );
    return Draggable<_Payload>(
      data: _Payload.boardPalette(item),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 96,
          child: _toolTile(
            label: item.label,
            icon: item.icon,
            color: item.color,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );
  }

  Widget _buildInstructionTool(_CodeBlock block) {
    final tile = _toolTile(
      label: block.label,
      color: block.color,
      icon: Icons.code_rounded,
      isInstruction: true,
    );

    return Draggable<_Payload>(
      data: _Payload.solutionBlock(block),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 118,
          child: _toolTile(
            label: block.label,
            color: block.color,
            icon: Icons.code_rounded,
            isInstruction: true,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: InkWell(
        onTap: () => _insertBlock(block),
        borderRadius: BorderRadius.circular(14),
        child: tile,
      ),
    );
  }

  Widget _allowedChip(_CodeBlock block) {
    return Draggable<_Payload>(
      data: _Payload.solutionTrayBlock(block),
      feedback: Material(
        color: Colors.transparent,
        child: _buildAllowedChipVisual(block),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _buildAllowedChipVisual(block),
      ),
      onDragStarted: () {
        setState(() {
          _isSolutionTrayBlockDragging = true;
        });
      },
      onDragEnd: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isSolutionTrayBlockDragging = false;
        });
      },
      child: InkWell(
        onTap: () => _insertBlock(block),
        borderRadius: BorderRadius.circular(16),
        child: _buildAllowedChipVisual(block),
      ),
    );
  }

  Widget _buildAllowedChipVisual(_CodeBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: block.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: block.color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.code_rounded, size: 16, color: block.color),
          const SizedBox(width: 8),
          Text(
            block.label,
            style: TextStyle(color: block.color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeAllowedBlock(block),
            child: Icon(Icons.close, size: 16, color: block.color),
          ),
        ],
      ),
    );
  }

  Widget _toolTile({
    required String label,
    required Color color,
    IconData? icon,
    bool isInstruction = false,
  }) {
    return Container(
      width: isInstruction ? 92 : 78,
      height: isInstruction ? 70 : 80,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: isInstruction ? 18 : 22),
            const SizedBox(height: 4),
          ],
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: isInstruction ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: isInstruction ? 13 : 12,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulerHandle() {
    return Draggable<_Payload>(
      data: const _Payload.ruler(),
      feedback: Material(
        color: Colors.transparent,
        child: Icon(
          Icons.straighten,
          color: Colors.teal.shade700,
          size: 30,
        ),
      ),
      onDragStarted: () {
        setState(() {
          _status = 'Drop the ruler onto the grid, then select two points.';
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _rulerActive ? Colors.teal.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _rulerActive ? Colors.teal.shade300 : Colors.blueGrey.shade200,
            width: 1.8,
          ),
        ),
        child: Icon(
          Icons.straighten,
          color: Colors.teal.shade700,
          size: 20,
        ),
      ),
    );
  }

  Widget _distanceBubble({
    required Offset position,
    required int distance,
    required bool preview,
  }) {
    return Positioned(
      left: position.dx + 12,
      top: position.dy - 12,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: preview ? Colors.teal.shade700 : Colors.blue.shade700,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            '$distance',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildTrash() {
    final isVisible = _isBoardItemDragging || _isSolutionTrayBlockDragging;

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        offset: isVisible ? Offset.zero : const Offset(0, 1.25),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: isVisible ? 1 : 0,
          child: DragTarget<_Payload>(
            onWillAcceptWithDetails: (details) {
              return details.data.kind == _PayloadKind.boardItem ||
                  details.data.kind == _PayloadKind.solutionTrayBlock;
            },
            onAcceptWithDetails: (details) {
              if (details.data.kind == _PayloadKind.boardItem &&
                  details.data.sourceCell != null) {
                _deleteItem(details.data.sourceCell!);
                return;
              }

              if (details.data.kind == _PayloadKind.solutionTrayBlock &&
                  details.data.block != null) {
                _deleteSolutionBlock(details.data.block!);
              }
            },
            builder: (context, candidateData, rejectedData) {
              final highlight = candidateData.any(
                (data) =>
                    data?.kind == _PayloadKind.boardItem ||
                    data?.kind == _PayloadKind.solutionTrayBlock,
              );
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: highlight
                      ? Colors.red.shade600
                      : Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: highlight ? Colors.red.shade600 : Colors.red.shade100,
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      highlight ? Icons.delete : Icons.delete_outline,
                      color: highlight ? Colors.white : Colors.red.shade600,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Drop to delete',
                      style: TextStyle(
                        color: highlight ? Colors.white : Colors.red.shade600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _boardIcon(_BoardItemType item, {bool small = false}) {
    final size = small ? 26.0 : 18.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(item == _BoardItemType.obstacle ? 5 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(item.icon, size: size * 0.56, color: Colors.white),
    );
  }

  Widget _buildSidebarSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.blueGrey.shade900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _windowFrame({
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

const List<_CodeBlock> _codeBlocks = <_CodeBlock>[
  _CodeBlock(
    id: 'step',
    label: 'step',
    insertText: 'step ',
    color: Color(0xFF1D4ED8),
    startsOnNewLine: true,
  ),
  _CodeBlock(
    id: 'turn',
    label: 'turn',
    insertText: 'turn ',
    color: Color(0xFF0F766E),
    startsOnNewLine: true,
  ),
  _CodeBlock(
    id: 'left',
    label: 'left',
    insertText: 'left',
    color: Color(0xFF7C3AED),
  ),
  _CodeBlock(
    id: 'right',
    label: 'right',
    insertText: 'right',
    color: Color(0xFFB45309),
  ),
];

enum _BoardItemType {
  obstacle('Obstacle', Icons.crop_square_rounded, Color(0xFF475569)),
  player('Player', Icons.navigation_rounded, Color(0xFF2563EB)),
  collectable('Collectable', Icons.star_rounded, Color(0xFFF59E0B)),
  goal('Goal', Icons.flag_rounded, Color(0xFFDC2626));

  const _BoardItemType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

enum _PayloadKind {
  boardPalette,
  boardItem,
  solutionBlock,
  solutionTrayBlock,
  ruler,
}

class _Payload {
  final _PayloadKind kind;
  final _BoardItemType? itemType;
  final _Cell? sourceCell;
  final _CodeBlock? block;

  const _Payload._({
    required this.kind,
    this.itemType,
    this.sourceCell,
    this.block,
  });

  const _Payload.boardPalette(_BoardItemType itemType)
    : this._(kind: _PayloadKind.boardPalette, itemType: itemType);
  const _Payload.boardItem(_BoardItemType itemType, _Cell sourceCell)
    : this._(
        kind: _PayloadKind.boardItem,
        itemType: itemType,
        sourceCell: sourceCell,
      );
  const _Payload.solutionBlock(_CodeBlock block)
    : this._(kind: _PayloadKind.solutionBlock, block: block);
  const _Payload.solutionTrayBlock(_CodeBlock block)
    : this._(kind: _PayloadKind.solutionTrayBlock, block: block);
  const _Payload.ruler() : this._(kind: _PayloadKind.ruler);
}

class _CodeBlock {
  final String id;
  final String label;
  final String insertText;
  final Color color;
  final bool startsOnNewLine;

  const _CodeBlock({
    required this.id,
    required this.label,
    required this.insertText,
    required this.color,
    this.startsOnNewLine = false,
  });
}

class _Cell {
  final int column;
  final int row;

  const _Cell({
    required this.column,
    required this.row,
  });

  @override
  bool operator ==(Object other) {
    return other is _Cell && other.column == column && other.row == row;
  }

  @override
  int get hashCode => Object.hash(column, row);
}
