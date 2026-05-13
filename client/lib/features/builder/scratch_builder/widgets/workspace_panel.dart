import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/block_templates.dart';
import '../models/block_template.dart';
import '../models/block_type.dart';
import '../models/workspace_block.dart';
import '../painters/grid_painter.dart';
import 'scratch_block.dart';

class WorkspacePanel extends StatefulWidget {
  final List<WorkspaceBlock> blocks;
  final BlockType? selectedCategory;
  final bool isDraggingWorkspaceBlock;
  final void Function(BlockType type) onCategoryPressed;
  final void Function(BlockTemplate template, Offset localPosition)
  onAcceptTemplate;
  final void Function(String id) onDetachBlock;
  final void Function(String id, Offset delta) onMoveBlockStack;
  final void Function(String id) onSnapBlockStack;
  final void Function(String id) onDeleteBlockStack;
  final void Function(String blockId, String inputKey, String value)
  onUpdateBlockInput;
  final void Function(bool isDragging) onWorkspaceDragStateChanged;

  const WorkspacePanel({
    super.key,
    required this.blocks,
    required this.selectedCategory,
    required this.isDraggingWorkspaceBlock,
    required this.onCategoryPressed,
    required this.onAcceptTemplate,
    required this.onDetachBlock,
    required this.onMoveBlockStack,
    required this.onSnapBlockStack,
    required this.onDeleteBlockStack,
    required this.onUpdateBlockInput,
    required this.onWorkspaceDragStateChanged,
  });

  @override
  State<WorkspacePanel> createState() => _WorkspacePanelState();
}

class _WorkspacePanelState extends State<WorkspacePanel> {
  final ScrollController _paletteScrollController = ScrollController();
  final GlobalKey _dropAreaKey = GlobalKey();

  @override
  void didUpdateWidget(covariant WorkspacePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedCategory != widget.selectedCategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_paletteScrollController.hasClients) return;
        _paletteScrollController.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _paletteScrollController.dispose();
    super.dispose();
  }

  void _scrollPalette(double delta) {
    if (!_paletteScrollController.hasClients) return;

    final nextOffset = (_paletteScrollController.offset + delta).clamp(
      0.0,
      _paletteScrollController.position.maxScrollExtent,
    );

    _paletteScrollController.animateTo(
      nextOffset,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;

    _scrollPalette(delta);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = widget.selectedCategory;
    final visibleBlocks = selectedCategory == null
        ? <BlockTemplate>[]
        : blockTemplates.where((b) => b.type == selectedCategory).toList();

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            Expanded(
              child: DragTarget<BlockTemplate>(
                onAcceptWithDetails: (details) {
                  final targetContext = _dropAreaKey.currentContext;
                  if (targetContext == null) return;

                  final box = targetContext.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(details.offset);
                  widget.onAcceptTemplate(details.data, localPosition);
                },
                builder: (context, candidateData, rejectedData) {
                  return Stack(
                    key: _dropAreaKey,
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: const Color(0xffeef5fb),
                          child: CustomPaint(painter: GridPainter()),
                        ),
                      ),
                      if (widget.blocks.isEmpty)
                        const Center(
                          child: Text(
                            'Drag blocks here',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                      ...widget.blocks.map(
                        (block) => Positioned(
                          left: block.position.dx,
                          top: block.position.dy,
                          child: Draggable<String>(
                            data: block.id,
                            feedback: Material(
                              color: Colors.transparent,
                              child: ScratchBlock(
                                template: block.template,
                                inputValues: block.inputValues,
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.35,
                              child: ScratchBlock(
                                template: block.template,
                                inputValues: block.inputValues,
                              ),
                            ),
                            onDragStarted: () {
                              widget.onWorkspaceDragStateChanged(true);
                              widget.onDetachBlock(block.id);
                            },
                            onDragUpdate: (details) {
                              widget.onMoveBlockStack(block.id, details.delta);
                            },
                            onDragEnd: (_) {
                              widget.onWorkspaceDragStateChanged(false);
                              widget.onSnapBlockStack(block.id);
                            },
                            onDraggableCanceled: (_, velocity) {
                              widget.onWorkspaceDragStateChanged(false);
                              widget.onSnapBlockStack(block.id);
                            },
                            child: ScratchBlock(
                              template: block.template,
                              blockId: block.id,
                              inputValues: block.inputValues,
                              onInputChanged: widget.onUpdateBlockInput,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 24,
                        top: 24,
                        child: AnimatedScale(
                          scale: widget.isDraggingWorkspaceBlock ? 1 : 0.6,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutBack,
                          child: AnimatedOpacity(
                            opacity: widget.isDraggingWorkspaceBlock ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: DragTarget<String>(
                              onAcceptWithDetails: (details) {
                                widget.onDeleteBlockStack(details.data);
                              },
                              builder: (context, candidate, rejected) {
                                final hovering = candidate.isNotEmpty;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: hovering ? 86 : 74,
                                  height: hovering ? 86 : 74,
                                  decoration: BoxDecoration(
                                    color: hovering
                                        ? Colors.red.shade400
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Icon(
                                    Icons.delete_rounded,
                                    size: hovering ? 46 : 40,
                                    color: hovering
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: selectedCategory == null ? 0 : 104,
              color: const Color(0xffe3e3e3),
              child: selectedCategory == null
                  ? const SizedBox.shrink()
                  : _PaletteBlockRow(
                      blocks: visibleBlocks,
                      controller: _paletteScrollController,
                      onPointerSignal: _handlePointerSignal,
                    ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                children: BlockType.values.map((type) {
                  final isSelected = selectedCategory == type;
                  final color = blockCategoryColors[type]!;
                  final name = blockCategoryNames[type]!;

                  return GestureDetector(
                    onTap: () => widget.onCategoryPressed(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? color : Colors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteBlockRow extends StatelessWidget {
  final List<BlockTemplate> blocks;
  final ScrollController controller;
  final void Function(PointerSignalEvent event) onPointerSignal;

  const _PaletteBlockRow({
    required this.blocks,
    required this.controller,
    required this.onPointerSignal,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: onPointerSignal,
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        notificationPredicate: (notification) {
          return notification.metrics.axis == Axis.horizontal;
        },
        child: ListView.separated(
          controller: controller,
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
          itemCount: blocks.length,
          separatorBuilder: (_, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final template = blocks[index];

            return Draggable<BlockTemplate>(
              data: template,
              feedback: Material(
                color: Colors.transparent,
                child: ScratchBlock(template: template),
              ),
              childWhenDragging: Opacity(
                opacity: 0.35,
                child: ScratchBlock(template: template),
              ),
              child: ScratchBlock(template: template),
            );
          },
        ),
      ),
    );
  }
}
