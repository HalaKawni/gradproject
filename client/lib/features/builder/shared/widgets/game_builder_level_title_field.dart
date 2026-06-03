import 'package:flutter/material.dart';

class GameBuilderLevelTitleField extends StatefulWidget {
  static const String? levelNameFontFamily = null;

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final double? width;

  const GameBuilderLevelTitleField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.width,
  });

  @override
  State<GameBuilderLevelTitleField> createState() =>
      _GameBuilderLevelTitleFieldState();
}

class _GameBuilderLevelTitleFieldState
    extends State<GameBuilderLevelTitleField> {
  static const double _tooltipWidth = 142;
  static const double _tooltipHorizontalOffset = 50;
  static const double _tooltipVerticalOffset = -4;

  bool _isHovered = false;
  Offset _tooltipPosition = Offset.zero;
  OverlayEntry? _tooltipEntry;

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = _titleStyle(context);
    final titleField = MouseRegion(
      cursor: SystemMouseCursors.text,
      onEnter: (event) {
        setState(() => _isHovered = true);
        _showTooltip();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hideTooltip();
      },
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: titleStyle.copyWith(
            color: Theme.of(context).hintColor,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        style: titleStyle,
        cursorColor: Colors.black,
        maxLines: 1,
        onChanged: widget.onChanged,
      ),
    );

    if (widget.width == null) {
      return titleField;
    }

    return SizedBox(width: widget.width, child: titleField);
  }

  void _showTooltip() {
    _tooltipPosition = _tooltipAnchorPosition();
    if (_tooltipEntry != null) {
      _tooltipEntry!.markNeedsBuild();
      return;
    }

    _tooltipEntry = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final maxLeft = screenWidth - _tooltipWidth - 8;
        final left = maxLeft <= 8
            ? 8.0
            : _tooltipPosition.dx.clamp(8.0, maxLeft).toDouble();

        return Positioned(
          left: left,
          top: _tooltipPosition.dy,
          child: IgnorePointer(
            child: SizedBox(
              width: _tooltipWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _TooltipArrow(color: Color(0xFF475A6D)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF475A6D),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      child: Text(
                        'Change name',
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.none,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_tooltipEntry!);
  }

  Offset _tooltipAnchorPosition() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) {
      return Offset.zero;
    }

    final topLeft = renderObject.localToGlobal(Offset.zero);
    return Offset(
      topLeft.dx + _tooltipHorizontalOffset,
      topLeft.dy + renderObject.size.height + _tooltipVerticalOffset,
    );
  }

  void _hideTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

  TextStyle _titleStyle(BuildContext context) {
    final baseStyle =
        Theme.of(context).textTheme.titleLarge ?? const TextStyle(fontSize: 22);

    return baseStyle.copyWith(
      fontFamily: GameBuilderLevelTitleField.levelNameFontFamily,
      decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
    );
  }
}

class _TooltipArrow extends StatelessWidget {
  final Color color;

  const _TooltipArrow({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(14, 8),
      painter: _TooltipArrowPainter(color),
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  final Color color;

  const _TooltipArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TooltipArrowPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
