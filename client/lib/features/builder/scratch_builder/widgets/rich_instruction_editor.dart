import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

class RichInstructionEditor extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final bool autoFocus;
  final double minHeight;
  final double maxHeight;

  const RichInstructionEditor({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.placeholder,
    this.autoFocus = false,
    this.minHeight = 190,
    this.maxHeight = 260,
  });

  @override
  State<RichInstructionEditor> createState() => _RichInstructionEditorState();
}

class _RichInstructionEditorState extends State<RichInstructionEditor> {
  late final QuillController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  late final ScrollController _toolbarScrollController;
  StreamSubscription<dynamic>? _changesSubscription;
  Timer? _saveDebounce;
  late String _lastSerializedValue;

  @override
  void initState() {
    super.initState();
    final document = _documentFromValue(widget.initialValue);
    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _toolbarScrollController = ScrollController();
    _lastSerializedValue = _serializeDocument(document);
    _listenToDocumentChanges();
  }

  void _listenToDocumentChanges() {
    _changesSubscription?.cancel();
    _changesSubscription = _controller.document.changes.listen((_) {
      _saveDebounce?.cancel();
      _saveDebounce = Timer(const Duration(milliseconds: 180), _emitChange);
    });
  }

  @override
  void didUpdateWidget(covariant RichInstructionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue == oldWidget.initialValue ||
        widget.initialValue == _lastSerializedValue) {
      return;
    }

    final document = _documentFromValue(widget.initialValue);
    _controller.document = document;
    _lastSerializedValue = _serializeDocument(document);
    _listenToDocumentChanges();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _changesSubscription?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _toolbarScrollController.dispose();
    super.dispose();
  }

  void _emitChange() {
    final nextValue = _serializeDocument(_controller.document);
    if (nextValue == _lastSerializedValue) return;

    _lastSerializedValue = nextValue;
    widget.onChanged(nextValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : const Color(0xffd9e1ea);
    final panelColor = isDark ? const Color(0xff111827) : Colors.white;
    final toolbarColor = isDark
        ? const Color(0xff1f2937)
        : const Color(0xfff8fafc);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: toolbarColor,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Scrollbar(
              controller: _toolbarScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              notificationPredicate: (notification) => notification.depth == 0,
              child: SingleChildScrollView(
                controller: _toolbarScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
                child: _InstructionToolbar(controller: _controller),
              ),
            ),
          ),
          SizedBox(
            height: widget.maxHeight,
            child: QuillEditor.basic(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              config: QuillEditorConfig(
                autoFocus: widget.autoFocus,
                minHeight: widget.minHeight,
                maxHeight: widget.maxHeight,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                placeholder: widget.placeholder,
                enableAlwaysIndentOnTab: true,
                customLinkPrefixes: const ['http', 'https', 'mailto'],
                embedBuilders: FlutterQuillEmbeds.defaultEditorBuilders(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Document _documentFromValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return Document();

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        return Document.fromJson(decoded);
      }
    } catch (_) {
      // Existing projects stored instruction text as plain strings. Treat that
      // as one editable paragraph and save as Delta after the next change.
    }

    final document = Document();
    document.insert(0, value);
    return document;
  }

  String _serializeDocument(Document document) {
    return jsonEncode(document.toDelta().toJson());
  }
}

class _InstructionToolbar extends StatelessWidget {
  final QuillController controller;

  const _InstructionToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      children: [
        QuillToolbarHistoryButton(isUndo: true, controller: controller),
        QuillToolbarHistoryButton(isUndo: false, controller: controller),
        const _ToolbarDivider(),
        QuillToolbarToggleStyleButton(
          controller: controller,
          attribute: Attribute.bold,
        ),
        QuillToolbarToggleStyleButton(
          controller: controller,
          attribute: Attribute.italic,
        ),
        QuillToolbarToggleStyleButton(
          controller: controller,
          attribute: Attribute.underline,
        ),
        QuillToolbarClearFormatButton(controller: controller),
        const _ToolbarDivider(),
        QuillToolbarColorButton(controller: controller, isBackground: false),
        QuillToolbarColorButton(controller: controller, isBackground: true),
        const _ToolbarDivider(),
        QuillToolbarSelectHeaderStyleDropdownButton(controller: controller),
        const _ToolbarDivider(),
        QuillToolbarToggleStyleButton(
          controller: controller,
          attribute: Attribute.ol,
        ),
        QuillToolbarToggleStyleButton(
          controller: controller,
          attribute: Attribute.ul,
        ),
        QuillToolbarToggleCheckListButton(controller: controller),
        QuillToolbarIndentButton(controller: controller, isIncrease: false),
        QuillToolbarIndentButton(controller: controller, isIncrease: true),
      ],
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 28,
      child: VerticalDivider(width: 10, thickness: 1),
    );
  }
}
