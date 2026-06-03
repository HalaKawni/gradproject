import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flutter conversion of the uploaded Blocks.html file.
///
/// Use it directly:
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockLibraryPage()));
///
/// Or reuse Scratch3Block inside your existing palette.
class BlockLibraryPage extends StatelessWidget {
  const BlockLibraryPage({super.key});

  static int get totalBlocks => blockCategories.fold<int>(
        0,
        (sum, cat) => sum + cat.blocks.length,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _BlockColors.bg,
      body: Column(
        children: [
          _Header(totalBlocks: totalBlocks, categoryCount: blockCategories.length),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 80),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    children: [
                      for (final category in blockCategories)
                        _CategorySection(category: category),
                      const SizedBox(height: 8),
                      const Text(
                        'Custom block shapes — original artwork. Drag and drop into your designs.',
                        style: TextStyle(color: _BlockColors.muted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.totalBlocks, required this.categoryCount});

  final int totalBlocks;
  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: _BlockColors.panel,
        border: Border(bottom: BorderSide(color: _BlockColors.line)),
      ),
      child: Row(
        children: [
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Block Library',
                style: TextStyle(
                  color: _BlockColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Click a value to edit it. Click empty block area to copy as SVG.',
                style: TextStyle(color: _BlockColors.muted, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '$totalBlocks blocks across $categoryCount categories',
            style: const TextStyle(color: _BlockColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category});

  final BlockCategoryDef category;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: _BlockColors.panel,
        border: Border.all(color: _BlockColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFBFBFD), Color(0xFFF4F5F8)],
              ),
              border: Border(bottom: BorderSide(color: _BlockColors.line)),
            ),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.18),
                        offset: const Offset(0, -2),
                        blurRadius: 0,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  category.name,
                  style: const TextStyle(
                    color: _BlockColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${category.blocks.length} block${category.blocks.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: _BlockColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          _DottedBlockArea(
            child: Wrap(
              spacing: 26,
              runSpacing: 22,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                for (final block in category.blocks)
                  Scratch3Block(
                    block: block,
                    color: category.color,
                    darkColor: category.darkColor,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: block.toSvgLikeString(category)));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          duration: Duration(milliseconds: 850),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: _BlockColors.ink,
                          content: Text('Copied SVG'),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _CategoryPill(category: category, outlined: false),
                _CategoryPill(category: category, outlined: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedBlockArea extends StatelessWidget {
  const _DottedBlockArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBackgroundPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
        child: child,
      ),
    );
  }
}

class _DottedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final paint = Paint()..color = const Color(0xFFE2E6ED);
    for (double y = 1; y < size.height; y += 18) {
      for (double x = 1; x < size.width; x += 18) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category, required this.outlined});

  final BlockCategoryDef category;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: outlined ? Colors.white : category.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: outlined ? category.darkColor : category.darkColor, width: 1.5),
      ),
      child: Text(
        category.name,
        style: TextStyle(
          color: outlined ? category.darkColor : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Reusable block widget for your current game builder palette.
class Scratch3Block extends StatefulWidget {
  const Scratch3Block({
    super.key,
    required this.block,
    required this.color,
    required this.darkColor,
    this.scale = 1,
    this.draggable = false,
    this.onTap,
    this.innerHeight,
    this.onFieldChanged,
  });

  final BlockDef block;
  final Color color;
  final Color darkColor;
  final double scale;
  final bool draggable;
  final VoidCallback? onTap;
  final double? innerHeight;
  final void Function(int fieldIndex, String value)? onFieldChanged;

  @override
  State<Scratch3Block> createState() => _Scratch3BlockState();
}

class _Scratch3BlockState extends State<Scratch3Block> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final metrics = widget.innerHeight != null
        ? _BlockMetrics.fromWithInner(widget.block, widget.innerHeight!)
        : _BlockMetrics.from(widget.block);
    final shape = widget.block.shape;
    final blockChild = AnimatedScale(
      scale: _hovered ? 1.025 : 1,
      duration: const Duration(milliseconds: 120),
      child: SizedBox(
        width: metrics.canvasWidth * widget.scale,
        height: metrics.canvasHeight * widget.scale,
        child: Transform.scale(
          alignment: Alignment.topLeft,
          scale: widget.scale,
          child: SizedBox(
            width: metrics.canvasWidth,
            height: metrics.canvasHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BlockShapePainter(
                      color: widget.color,
                      darkColor: widget.darkColor,
                      shape: shape,
                      isHat: shape == BlockShape.hat,
                      isReporter: shape == BlockShape.reporter,
                      isBoolean: shape == BlockShape.boolean,
                      isCBlock: shape == BlockShape.cBlock,
                      headH: _ShapeConstants.stackH,
                      footH: _ShapeConstants.footH,
                    ),
                  ),
                ),
                _BlockContentOverlay(block: widget.block, metrics: metrics, onFieldChanged: widget.onFieldChanged),
              ],
            ),
          ),
        ),
      ),
    );

    // Workspace blocks (not draggable, no onTap) don't need hover tracking.
    // Skipping MouseRegion avoids recursive mouse_tracker assertion errors.
    if (!widget.draggable && widget.onTap == null) return blockChild;

    final interactive = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: blockChild),
    );

    if (!widget.draggable) return interactive;

    return Draggable<BlockDef>(
      data: widget.block,
      feedback: Material(
        color: Colors.transparent,
        child: Scratch3Block(
          block: widget.block,
          color: widget.color,
          darkColor: widget.darkColor,
          scale: widget.scale,
        ),
      ),
      childWhenDragging: Opacity(opacity: .35, child: interactive),
      child: interactive,
    );
  }
}

class _BlockContentOverlay extends StatelessWidget {
  const _BlockContentOverlay({required this.block, required this.metrics, this.onFieldChanged});

  final BlockDef block;
  final _BlockMetrics metrics;
  final void Function(int fieldIndex, String value)? onFieldChanged;

  @override
  Widget build(BuildContext context) {
    switch (block.shape) {
      case BlockShape.hat:
        return Positioned(
          left: metrics.padding + 14,
          top: metrics.padding,
          width: metrics.width,
          height: metrics.lipHeight,
          child: _BlockTextRow(label: block.label, fields: block.fields, onFieldChanged: onFieldChanged),
        );
      case BlockShape.cBlock:
        return Stack(
          children: [
            Positioned(
              left: metrics.padding + 14,
              top: metrics.padding,
              width: metrics.width,
              height: metrics.lipHeight,
              child: _BlockTextRow(label: block.label, fields: block.fields, onFieldChanged: onFieldChanged),
            ),
            if (block.elseRow != null)
              Positioned(
                left: metrics.padding + 14,
                top: metrics.padding + metrics.lipHeight + metrics.mouthHeight,
                width: metrics.width,
                height: _ShapeConstants.footH,
                child: _BlockTextRow(
                  label: block.elseRow!.label,
                  fields: block.elseRow!.fields,
                  onFieldChanged: onFieldChanged,
                ),
              ),
          ],
        );
      case BlockShape.reporter:
      case BlockShape.boolean:
      case BlockShape.stack:
        return Positioned(
          left: metrics.padding + _ShapeConstants.pad,
          top: metrics.padding,
          width: metrics.width,
          height: metrics.height,
          child: block.multilineBelow == null
              ? _BlockTextRow(label: block.label, fields: block.fields, onFieldChanged: onFieldChanged)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BlockTextRow(label: block.label, fields: block.fields, height: 24, onFieldChanged: onFieldChanged),
                    _BlockTextRow(label: block.multilineBelow!, fields: const [], height: 18),
                  ],
                ),
        );
    }
  }
}

class _BlockTextRow extends StatelessWidget {
  const _BlockTextRow({required this.label, required this.fields, this.height, this.onFieldChanged});

  final String label;
  final List<BlockFieldDef> fields;
  final double? height;
  final void Function(int fieldIndex, String value)? onFieldChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (label.isNotEmpty) _BlockLabel(label),
          for (int fi = 0; fi < fields.length; fi++) ...[
            if (label.isNotEmpty || fi > 0) const SizedBox(width: 6),
            _BlockField(
              fields[fi],
              onChanged: onFieldChanged != null ? (v) => onFieldChanged!(fi, v) : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _BlockLabel extends StatelessWidget {
  const _BlockLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.visible,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        shadows: [Shadow(color: Color(0x33000000), offset: Offset(0, 1))],
      ),
    );
  }
}

class _BlockField extends StatelessWidget {
  const _BlockField(this.field, {this.onChanged});

  final BlockFieldDef field;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    switch (field.kind) {
      case BlockFieldKind.gear:
        return Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFF5B6ED8), borderRadius: BorderRadius.circular(4)),
          child: const Text('⚙', style: TextStyle(color: Colors.white, fontSize: 11, height: 1)),
        );
      case BlockFieldKind.question:
        return Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xDDFFFFFF), shape: BoxShape.circle),
          child: const Text('?', style: TextStyle(color: _BlockColors.ink, fontSize: 12, fontWeight: FontWeight.w700)),
        );
      case BlockFieldKind.slot:
        return Container(
          width: field.width ?? 16,
          height: 14,
          decoration: BoxDecoration(color: Colors.black.withOpacity(.22), borderRadius: BorderRadius.circular(999)),
        );
      case BlockFieldKind.label:
        return _BlockLabel(field.label);
      case BlockFieldKind.text:
        return _TextValueChip(width: field.width ?? 60);
      case BlockFieldKind.number:
        return _EditableValueChip(
          initial: '${field.value ?? 0}',
          width: field.width ?? math.max(20, '${field.value ?? 0}'.length * 8 + 8),
          round: true,
          onChanged: onChanged,
        );
      case BlockFieldKind.dropdown:
      case BlockFieldKind.op:
        return _DropdownLikeChip(
          label: field.label,
          width: field.width,
          round: field.kind == BlockFieldKind.op,
          options: field.options,
          onChanged: onChanged,
        );
    }
  }
}

class _EditableValueChip extends StatefulWidget {
  const _EditableValueChip({required this.initial, required this.width, required this.round, this.onChanged});

  final String initial;
  final double width;
  final bool round;
  final ValueChanged<String>? onChanged;

  @override
  State<_EditableValueChip> createState() => _EditableValueChipState();
}

class _EditableValueChipState extends State<_EditableValueChip> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void didUpdateWidget(_EditableValueChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Do NOT update _controller.text here: calling the controller's text setter
    // fires TextEditingController.notifyListeners() which causes EditableText to
    // call setState during the parent's build pass → "setState during build" error.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.round ? 999 : 4),
        border: Border.all(color: Colors.black.withOpacity(.18)),
      ),
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _BlockColors.ink),
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _DropdownLikeChip extends StatefulWidget {
  const _DropdownLikeChip({
    required this.label,
    this.width,
    this.round = false,
    this.options = const [],
    this.onChanged,
  });

  final String label;
  final double? width;
  final bool round;
  final List<String> options;
  final ValueChanged<String>? onChanged;

  @override
  State<_DropdownLikeChip> createState() => _DropdownLikeChipState();
}

class _DropdownLikeChipState extends State<_DropdownLikeChip> {
  late String _current = widget.label;
  late final TextEditingController _controller = TextEditingController(text: widget.label);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showPopup(BuildContext ctx) async {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final selected = await showMenu<String>(
      context: ctx,
      position: RelativeRect.fromLTRB(
        offset.dx, offset.dy + box.size.height + 2,
        offset.dx + box.size.width, offset.dy + box.size.height + 2,
      ),
      items: [
        for (final opt in widget.options)
          PopupMenuItem(
            value: opt,
            height: 36,
            child: Row(
              children: [
                if (opt == _current)
                  const Text('✓ ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(opt, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
      ],
    );
    if (selected != null && selected != _current) {
      if (!mounted) return;
      setState(() {
        _current = selected;
        _controller.text = selected;
      });
      widget.onChanged?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width ?? math.max(28, _current.length * 7 + 22).toDouble();
    final hasOptions = widget.options.isNotEmpty;
    final chip = Container(
      width: width,
      height: 22,
      padding: const EdgeInsets.only(left: 5, right: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.round ? 999 : 4),
        border: Border.all(color: Colors.black.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: hasOptions
                ? Text(
                    _current,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _BlockColors.ink),
                  )
                : TextField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _BlockColors.ink),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
          ),
          const Text('▾', style: TextStyle(fontSize: 9, color: Color(0xAA1F2430))),
        ],
      ),
    );

    if (!hasOptions) return chip;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showPopup(context),
      child: chip,
    );
  }
}

class _TextValueChip extends StatelessWidget {
  const _TextValueChip({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('“', style: TextStyle(fontSize: 12, color: _BlockColors.ink, fontWeight: FontWeight.w600)),
          Container(
            width: math.max(14, width - 28),
            height: 14,
            decoration: BoxDecoration(color: const Color(0xFFEEF0F5), borderRadius: BorderRadius.circular(3)),
          ),
          const Text('”', style: TextStyle(fontSize: 12, color: _BlockColors.ink, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── HTML-ported shape constants ───────────────────────────────────────────────

class _ShapeConstants {
  static const double R = 5;     // corner radius
  static const double NX = 13;   // notch X start
  static const double NW = 20;   // notch width
  static const double ND = 5;    // notch depth (tab overflow below block)
  static const double ARM = 16;  // C-block mouth left indent
  static const double HAT_R = 14;// hat curve radius
  static const double stroke = 1.5;
  static const double stackH = 33;    // stack block content height
  static const double reporterH = 25; // reporter content height
  static const double booleanH = 25;  // boolean content height
  static const double padX = 14;      // horizontal content padding
  static const double footH = 13;     // C-block foot height
  static const double minStackW = 80.0;
  static const double minCBlockW = 120.0;
  static const double minReporterW = 56.0;
  static const double pad = 14;
}

// ── HTML-ported path generator ────────────────────────────────────────────────

class _BlockPaths {
  static const double _R = _ShapeConstants.R;
  static const double _NX = _ShapeConstants.NX;
  static const double _NW = _ShapeConstants.NW;
  static const double _ND = _ShapeConstants.ND;
  static const double _ARM = _ShapeConstants.ARM;
  static const double _HAT_R = _ShapeConstants.HAT_R;

  // Notch at top (groove going DOWN into block – accepts tab from block above)
  static void _topNotch(Path p) {
    p.lineTo(_NX, 0);
    p.cubicTo(_NX + 2, _ND, _NX + _NW - 2, _ND, _NX + _NW, 0);
  }

  // Tab at bottom (protrudes DOWN below block – inserts into notch of block below)
  static void _bottomTab(Path p, double H) {
    p.lineTo(_NX + _NW, H);
    p.cubicTo(_NX + _NW - 2, H + _ND, _NX + 2, H + _ND, _NX, H);
  }

  /// Stack block (H = body height, tab protrudes to H+ND below widget bounds).
  static Path stack(double W, double H, {bool topNotch = true, bool bottomTab = true}) {
    final p = Path();
    p.moveTo(_R, 0);
    if (topNotch) _topNotch(p);
    p.lineTo(W - _R, 0);
    p.arcToPoint(Offset(W, _R), radius: const Radius.circular(_R));
    p.lineTo(W, H - _R);
    p.arcToPoint(Offset(W - _R, H), radius: const Radius.circular(_R));
    if (bottomTab) _bottomTab(p, H);
    p.lineTo(_R, H);
    p.arcToPoint(Offset(0, H - _R), radius: const Radius.circular(_R));
    p.lineTo(0, _R);
    p.arcToPoint(Offset(_R, 0), radius: const Radius.circular(_R));
    p.close();
    return p;
  }

  /// Hat block (no top notch, curved top-left, bottom tab).
  static Path hat(double W, double H) {
    final p = Path();
    p.moveTo(0, _HAT_R);
    p.cubicTo(0, 4, 6, 0, _HAT_R + 4, 0);
    p.lineTo(W - _R, 0);
    p.arcToPoint(Offset(W, _R), radius: const Radius.circular(_R));
    p.lineTo(W, H - _R);
    p.arcToPoint(Offset(W - _R, H), radius: const Radius.circular(_R));
    _bottomTab(p, H);
    p.lineTo(_R, H);
    p.arcToPoint(Offset(0, H - _R), radius: const Radius.circular(_R));
    p.lineTo(0, _HAT_R);
    p.close();
    return p;
  }

  /// Reporter (pill/oval).
  static Path reporter(double W, double H) {
    final r = H / 2;
    return Path()
      ..moveTo(r, 0)
      ..lineTo(W - r, 0)
      ..arcToPoint(Offset(W, r), radius: Radius.circular(r))
      ..arcToPoint(Offset(W - r, H), radius: Radius.circular(r))
      ..lineTo(r, H)
      ..arcToPoint(Offset(0, H - r), radius: Radius.circular(r))
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..close();
  }

  /// Boolean (hexagonal).
  static Path boolean(double W, double H) {
    final k = H / 2;
    return Path()
      ..moveTo(k, 0)
      ..lineTo(W - k, 0)
      ..lineTo(W, H / 2)
      ..lineTo(W - k, H)
      ..lineTo(k, H)
      ..lineTo(0, H / 2)
      ..close();
  }

  /// C-block (headH + innerH + footH, tab protrudes below).
  static Path cBlock(double W, double headH, double innerH, double footH) {
    final y1 = headH;
    final y2 = headH + innerH;
    final y3 = headH + innerH + footH;
    final p = Path();
    // top notch
    p.moveTo(_R, 0);
    _topNotch(p);
    p.lineTo(W - _R, 0);
    p.arcToPoint(Offset(W, _R), radius: const Radius.circular(_R));
    // right side of head
    p.lineTo(W, y1);
    // mouth opening – notch for inner blocks' top notch
    p.lineTo(_ARM + _NX + _NW, y1);
    p.cubicTo(_ARM + _NX + _NW - 2, y1 + _ND, _ARM + _NX + 2, y1 + _ND, _ARM + _NX, y1);
    p.lineTo(_ARM, y1);
    // left wall of mouth going down
    p.lineTo(_ARM, y2);
    // bottom of mouth back to full width
    p.lineTo(W, y2);
    // foot right side
    p.lineTo(W, y3 - _R);
    p.arcToPoint(Offset(W - _R, y3), radius: const Radius.circular(_R));
    // bottom tab
    _bottomTab(p, y3);
    p.lineTo(_R, y3);
    p.arcToPoint(Offset(0, y3 - _R), radius: const Radius.circular(_R));
    // left side back up
    p.lineTo(0, _R);
    p.arcToPoint(Offset(_R, 0), radius: const Radius.circular(_R));
    p.close();
    return p;
  }

}

// ── Shape painter ─────────────────────────────────────────────────────────────

class _BlockShapePainter extends CustomPainter {
  const _BlockShapePainter({
    required this.color,
    required this.darkColor,
    required this.shape,
    // For stack/hat: size.height includes ND tab overflow
    this.isHat = false,
    this.isReporter = false,
    this.isBoolean = false,
    // For C-blocks
    this.isCBlock = false,
    this.headH = 33,
    this.footH = 13,
  });

  final Color color;
  final Color darkColor;
  final BlockShape shape;
  final bool isHat;
  final bool isReporter;
  final bool isBoolean;
  final bool isCBlock;
  final double headH;
  final double footH;

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;
    const nd = _ShapeConstants.ND;
    Path path;
    if (isCBlock) {
      // H includes ND tab overflow at bottom
      final innerH = math.max(1.0, H - headH - footH - nd);
      path = _BlockPaths.cBlock(W, headH, innerH, footH);
    } else if (isHat) {
      // H includes ND tab at bottom; hat body = H - ND
      path = _BlockPaths.hat(W, H - nd);
    } else if (isReporter) {
      path = _BlockPaths.reporter(W, H);
    } else if (isBoolean) {
      path = _BlockPaths.boolean(W, H);
    } else {
      // Stack: H includes ND tab at bottom; body = H - ND
      path = _BlockPaths.stack(W, H - nd);
    }

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.12), 1.5, false);
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = darkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ShapeConstants.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BlockShapePainter old) =>
      old.color != color || old.darkColor != darkColor ||
      old.isCBlock != isCBlock || old.isHat != isHat;
}

// ── Block metrics (kept for canvasWidth used in snap calculations) ─────────────

class _BlockMetrics {
  const _BlockMetrics({
    required this.width,
    required this.height,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.padding,
    this.lipWidth = 0,
    this.lipHeight = 33,
    this.mouthHeight = 30,
    this.leftTab = true,
    this.rightNotch = true,
    this.hasElse = false,
  });

  final double width;
  final double height;
  final double canvasWidth;
  final double canvasHeight;
  final double padding;
  final double lipWidth;
  final double lipHeight;
  final double mouthHeight;
  final bool leftTab;
  final bool rightNotch;
  final bool hasElse;

  static _BlockMetrics from(BlockDef block) {
    const nd = _ShapeConstants.ND;
    const stackH = _ShapeConstants.stackH;
    const reporterH = _ShapeConstants.reporterH;
    const booleanH = _ShapeConstants.booleanH;
    const footH = _ShapeConstants.footH;
    const padX = _ShapeConstants.padX;
    const minStackW = _ShapeConstants.minStackW;
    const minCBlockW = _ShapeConstants.minCBlockW;
    const minReporterW = _ShapeConstants.minReporterW;
    final contentW = _contentWidth(block.label, block.fields);
    switch (block.shape) {
      case BlockShape.stack:
        final h = block.multilineBelow == null ? stackH : stackH + 18;
        final w = block.width ?? math.max(minStackW, contentW + padX * 2);
        return _BlockMetrics(width: w, height: h, canvasWidth: w + nd, canvasHeight: h + nd, padding: 0,
            leftTab: block.leftTab, rightNotch: block.rightNotch);
      case BlockShape.reporter:
        final w = block.width ?? math.max(minReporterW, contentW + 26);
        return _BlockMetrics(width: w, height: reporterH, canvasWidth: w, canvasHeight: reporterH, padding: 0);
      case BlockShape.boolean:
        final w = block.width ?? math.max(minReporterW, contentW + 30);
        return _BlockMetrics(width: w, height: booleanH, canvasWidth: w, canvasHeight: booleanH, padding: 0);
      case BlockShape.hat:
        final w = block.width ?? math.max(minStackW, contentW + padX * 2);
        return _BlockMetrics(width: w, height: stackH, canvasWidth: w + nd, canvasHeight: stackH + nd,
            padding: 0, lipWidth: w, lipHeight: stackH);
      case BlockShape.cBlock:
        final w = block.width ?? math.max(minCBlockW, contentW + padX * 2);
        final h = stackH + 30.0 + footH;
        return _BlockMetrics(width: w, height: h, canvasWidth: w + nd, canvasHeight: h + nd,
            padding: 0, lipWidth: w, lipHeight: stackH, mouthHeight: 30, hasElse: block.elseRow != null);
    }
  }

  /// C-block variant with a dynamic inner slot height (expands to fit blocks placed inside).
  static _BlockMetrics fromWithInner(BlockDef block, double innerH) {
    if (block.shape != BlockShape.cBlock) return from(block);
    const nd = _ShapeConstants.ND;
    const stackH = _ShapeConstants.stackH;
    const footH = _ShapeConstants.footH;
    const padX = _ShapeConstants.padX;
    const minCBlockW = _ShapeConstants.minCBlockW;
    final contentW = _contentWidth(block.label, block.fields);
    final w = block.width ?? math.max(minCBlockW, contentW + padX * 2);
    final h = stackH + innerH + footH;
    return _BlockMetrics(width: w, height: h, canvasWidth: w + nd, canvasHeight: h + nd,
        padding: 0, lipWidth: w, lipHeight: stackH, mouthHeight: innerH, hasElse: block.elseRow != null);
  }

  static double _contentWidth(String label, List<BlockFieldDef> fields) {
    return _labelWidth(label) + fields.fold<double>(0, (s, f) => s + f.renderWidth + 6);
  }

  static double _labelWidth(String text) => (text.length * 9.0).ceilToDouble();

  @override
  bool operator ==(Object other) =>
      other is _BlockMetrics && other.width == width && other.height == height &&
      other.canvasWidth == canvasWidth && other.lipHeight == lipHeight;

  @override
  int get hashCode => Object.hash(width, height, canvasWidth, canvasHeight);
}

enum BlockShape { stack, reporter, boolean, hat, cBlock }

enum BlockFieldKind { dropdown, number, text, slot, op, label, gear, question }

class BlockCategoryDef {
  const BlockCategoryDef({
    required this.key,
    required this.name,
    required this.color,
    required this.darkColor,
    required this.blocks,
  });

  final String key;
  final String name;
  final Color color;
  final Color darkColor;
  final List<BlockDef> blocks;
}

class BlockDef {
  const BlockDef({
    required this.shape,
    required this.label,
    this.fields = const [],
    this.width,
    this.leftTab = true,
    this.rightNotch = true,
    this.multilineBelow,
    this.elseRow,
  });

  final BlockShape shape;
  final String label;
  final List<BlockFieldDef> fields;
  final double? width;
  final bool leftTab;
  final bool rightNotch;
  final String? multilineBelow;
  final ElseRowDef? elseRow;

  String get labelForMessage => label.isEmpty ? 'Custom' : label;

  String toSvgLikeString(BlockCategoryDef category) {
    final fieldText = fields.map((f) => f.label.isNotEmpty ? f.label : '${f.value ?? f.kind.name}').join(' ');
    return '<!-- Flutter block converted from Blocks.html -->\n'
        '<block shape=\"${shape.name}\" category=\"${category.name}\" color=\"${category.color.value.toRadixString(16)}\">'
        '${label.isEmpty ? '' : label} ${fieldText.trim()}'
        '</block>';
  }
}

class ElseRowDef {
  const ElseRowDef({required this.label, this.fields = const []});

  final String label;
  final List<BlockFieldDef> fields;
}

class BlockFieldDef {
  const BlockFieldDef._({
    required this.kind,
    this.label = '',
    this.value,
    this.width,
    this.options = const [],
  });

  final BlockFieldKind kind;
  final String label;
  final Object? value;
  final double? width;
  final List<String> options;

  const BlockFieldDef.dropdown(String label, {double? width, List<String> options = const []})
      : this._(kind: BlockFieldKind.dropdown, label: label, width: width, options: options);
  const BlockFieldDef.number(Object value, {double? width}) : this._(kind: BlockFieldKind.number, value: value, width: width);
  const BlockFieldDef.text({double? width}) : this._(kind: BlockFieldKind.text, width: width);
  const BlockFieldDef.slot({double? width}) : this._(kind: BlockFieldKind.slot, width: width);
  const BlockFieldDef.op(String label, {double? width}) : this._(kind: BlockFieldKind.op, label: label, width: width);
  const BlockFieldDef.label(String label, {double? width}) : this._(kind: BlockFieldKind.label, label: label, width: width);
  const BlockFieldDef.gear() : this._(kind: BlockFieldKind.gear);
  const BlockFieldDef.question() : this._(kind: BlockFieldKind.question);

  double get renderWidth {
    if (width != null) return width!;
    switch (kind) {
      case BlockFieldKind.gear:
      case BlockFieldKind.question:
        return 18;
      case BlockFieldKind.slot:
        return 16;
      case BlockFieldKind.text:
        return 60;
      case BlockFieldKind.number:
        return math.max(20, '${value ?? 0}'.length * 8 + 8).toDouble();
      case BlockFieldKind.dropdown:
        return math.max(28, label.length * 7 + 22).toDouble();
      case BlockFieldKind.op:
        return math.max(24, label.length * 7 + 22).toDouble();
      case BlockFieldKind.label:
        return math.max(20, label.length * 7).toDouble();
    }
  }
}

class _BlockColors {
  static const Color bg = Color(0xFFF6F7F9);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1F2430);
  static const Color muted = Color(0xFF5C6473);
  static const Color line = Color(0xFFE3E6ED);

  static const Color movement = Color(0xFF79B04E);
  static const Color movementD = Color(0xFF5A8A36);
  static const Color events = Color(0xFFA55454);
  static const Color eventsD = Color(0xFF7E3838);
  static const Color display = Color(0xFF7A7AB8);
  static const Color displayD = Color(0xFF5A5A99);
  static const Color widgets = Color(0xFF5B8BAD);
  static const Color widgetsD = Color(0xFF436E8D);
  static const Color gameSound = Color(0xFF9A6EA1);
  static const Color gameSoundD = Color(0xFF774E7E);
  static const Color control = Color(0xFF5FAE8B);
  static const Color controlD = Color(0xFF418A6A);
  static const Color logic = Color(0xFFB8945F);
  static const Color logicD = Color(0xFF936F3F);
  static const Color variables = Color(0xFF4FAAA3);
  static const Color variablesD = Color(0xFF338884);
  static const Color objFn = Color(0xFFA65C7E);
  static const Color objFnD = Color(0xFF82425F);
  static const Color otherObjFn = Color(0xFF9B4C72);
  static const Color otherObjFnD = Color(0xFF783556);
  static const Color ai = Color(0xFFA8AC5D);
  static const Color aiD = Color(0xFF82863F);
}

const List<BlockCategoryDef> blockCategories = [
  BlockCategoryDef(
    key: 'movement',
    name: 'Movement',
    color: _BlockColors.movement,
    darkColor: _BlockColors.movementD,
    blocks: [
      BlockDef(shape: BlockShape.stack, label: 'Step', fields: [BlockFieldDef.number(1, width: 22)]),
      BlockDef(shape: BlockShape.stack, label: 'Jump', fields: [BlockFieldDef.number(1, width: 22)]),
      BlockDef(shape: BlockShape.stack, label: 'Get X', rightNotch: false),
      BlockDef(shape: BlockShape.stack, label: 'Get Y', rightNotch: false),
      BlockDef(shape: BlockShape.stack, label: 'Set X', fields: [BlockFieldDef.number(300, width: 34)]),
      BlockDef(shape: BlockShape.stack, label: 'Set Y', fields: [BlockFieldDef.number(200, width: 34)]),
      BlockDef(shape: BlockShape.stack, label: 'Change X By', fields: [BlockFieldDef.number(0, width: 22)]),
      BlockDef(shape: BlockShape.stack, label: 'Change Y By', fields: [BlockFieldDef.number(0, width: 22)]),
      BlockDef(shape: BlockShape.stack, label: 'Get Rotation', rightNotch: false),
      BlockDef(shape: BlockShape.stack, label: 'Set Rotation', fields: [BlockFieldDef.number(0, width: 22)]),
      BlockDef(shape: BlockShape.stack, label: 'Change Rotation By', fields: [BlockFieldDef.number(0, width: 22)]),
      BlockDef(shape: BlockShape.stack, label: 'Set Speed', fields: [BlockFieldDef.number(1, width: 22)]),
      BlockDef(shape: BlockShape.stack, label: 'Set Allow Gravity', fields: [BlockFieldDef.dropdown('true')]),
      BlockDef(shape: BlockShape.stack, label: 'Get Distance From', fields: [BlockFieldDef.dropdown('Oliver')]),
      BlockDef(shape: BlockShape.stack, label: 'From', multilineBelow: 'get', fields: [BlockFieldDef.dropdown('Oliver')], rightNotch: false),
    ],
  ),
  BlockCategoryDef(
    key: 'events',
    name: 'Events',
    color: _BlockColors.events,
    darkColor: _BlockColors.eventsD,
    blocks: [
      BlockDef(shape: BlockShape.hat, label: 'On Key', fields: [BlockFieldDef.dropdown('→')]),
      BlockDef(shape: BlockShape.hat, label: 'On Collide', fields: [BlockFieldDef.dropdown('Oliver')]),
      BlockDef(shape: BlockShape.hat, label: 'On Collide With World Bounds'),
      BlockDef(shape: BlockShape.hat, label: 'On Collide With World Bounds', fields: [BlockFieldDef.dropdown('Left')]),
      BlockDef(shape: BlockShape.hat, label: 'On Swipe', fields: [BlockFieldDef.dropdown('Left')]),
      BlockDef(shape: BlockShape.hat, label: 'On Click'),
      BlockDef(shape: BlockShape.hat, label: 'On Update'),
      BlockDef(shape: BlockShape.hat, label: 'On Game Tap'),
      BlockDef(shape: BlockShape.hat, label: 'On Drag End'),
    ],
  ),
  BlockCategoryDef(
    key: 'display',
    name: 'Display',
    color: _BlockColors.display,
    darkColor: _BlockColors.displayD,
    blocks: [
      BlockDef(shape: BlockShape.stack, label: 'Show'),
      BlockDef(shape: BlockShape.stack, label: 'Hide'),
      BlockDef(shape: BlockShape.stack, label: 'Destroy'),
      BlockDef(shape: BlockShape.stack, label: 'Disable'),
      BlockDef(shape: BlockShape.stack, label: 'Enable'),
      BlockDef(shape: BlockShape.stack, label: 'Set Scale', fields: [BlockFieldDef.number(1, width: 22)]),
      BlockDef(shape: BlockShape.stack, label: 'Get Scale', rightNotch: false),
    ],
  ),
  BlockCategoryDef(
    key: 'widgets',
    name: 'Widgets',
    color: _BlockColors.widgets,
    darkColor: _BlockColors.widgetsD,
    blocks: [
      BlockDef(shape: BlockShape.stack, label: 'Set counter:', fields: [BlockFieldDef.dropdown(''), BlockFieldDef.label('To'), BlockFieldDef.number(1, width: 22)]),
      BlockDef(shape: BlockShape.stack, label: 'Change counter:', fields: [BlockFieldDef.dropdown(''), BlockFieldDef.label('By'), BlockFieldDef.number(1, width: 22)]),
      BlockDef(shape: BlockShape.stack, label: 'Set text:', fields: [BlockFieldDef.dropdown(''), BlockFieldDef.label('To'), BlockFieldDef.text()]),
      BlockDef(shape: BlockShape.stack, label: 'Set timer:', fields: [BlockFieldDef.dropdown(''), BlockFieldDef.label('To'), BlockFieldDef.number(1, width: 22)]),
      BlockDef(shape: BlockShape.stack, label: 'Start clock:', fields: [BlockFieldDef.dropdown('')]),
      BlockDef(shape: BlockShape.stack, label: 'Get', fields: [BlockFieldDef.dropdown(''), BlockFieldDef.label('Value')], rightNotch: false),
      BlockDef(shape: BlockShape.stack, label: 'Get', fields: [BlockFieldDef.dropdown(''), BlockFieldDef.label('Seconds')], rightNotch: false),
    ],
  ),
  BlockCategoryDef(
    key: 'gamesound',
    name: 'Game and Sounds',
    color: _BlockColors.gameSound,
    darkColor: _BlockColors.gameSoundD,
    blocks: [
      BlockDef(shape: BlockShape.stack, label: 'Play', multilineBelow: 'Sound', fields: [BlockFieldDef.dropdown('')]),
      BlockDef(shape: BlockShape.stack, label: 'Reset Game'),
      BlockDef(shape: BlockShape.stack, label: 'Pause Game'),
      BlockDef(shape: BlockShape.stack, label: 'Unpause Game'),
      BlockDef(shape: BlockShape.stack, label: 'Get Game Time', rightNotch: false),
      BlockDef(shape: BlockShape.stack, label: 'Set Background', fields: [BlockFieldDef.dropdown('jungle')]),
    ],
  ),
  BlockCategoryDef(
    key: 'control',
    name: 'Control',
    color: _BlockColors.control,
    darkColor: _BlockColors.controlD,
    blocks: [
      BlockDef(shape: BlockShape.cBlock, label: 'Loop'),
      BlockDef(shape: BlockShape.cBlock, label: 'Repeat', fields: [BlockFieldDef.number(10, width: 22), BlockFieldDef.label('times')]),
      BlockDef(shape: BlockShape.cBlock, label: 'if', fields: [BlockFieldDef.gear(), BlockFieldDef.slot(width: 18)]),
      BlockDef(shape: BlockShape.cBlock, label: 'if', fields: [BlockFieldDef.gear(), BlockFieldDef.slot(width: 18)], elseRow: ElseRowDef(label: 'else')),
    ],
  ),
  BlockCategoryDef(
    key: 'logic',
    name: 'Logic and Data',
    color: _BlockColors.logic,
    darkColor: _BlockColors.logicD,
    blocks: [
      BlockDef(shape: BlockShape.boolean, label: 'not', fields: [BlockFieldDef.slot(width: 14)]),
      BlockDef(shape: BlockShape.boolean, label: '', fields: [BlockFieldDef.slot(width: 14), BlockFieldDef.op('and'), BlockFieldDef.slot(width: 14)], width: 130),
      BlockDef(shape: BlockShape.boolean, label: '', fields: [BlockFieldDef.slot(width: 14), BlockFieldDef.op('='), BlockFieldDef.slot(width: 14)], width: 120),
      BlockDef(shape: BlockShape.reporter, label: '0', width: 46),
      BlockDef(shape: BlockShape.reporter, label: '', fields: [BlockFieldDef.text()], width: 60),
      BlockDef(shape: BlockShape.reporter, label: '', fields: [BlockFieldDef.number(1, width: 14), BlockFieldDef.op('+'), BlockFieldDef.number(1, width: 14)], width: 108),
      BlockDef(shape: BlockShape.reporter, label: 'Random from', fields: [BlockFieldDef.number(0, width: 18), BlockFieldDef.label('to'), BlockFieldDef.number(100, width: 30)]),
    ],
  ),
  BlockCategoryDef(
    key: 'variables',
    name: 'Variables',
    color: _BlockColors.variables,
    darkColor: _BlockColors.variablesD,
    blocks: [
      BlockDef(shape: BlockShape.stack, label: 'Set', fields: [BlockFieldDef.dropdown(''), BlockFieldDef.label('To'), BlockFieldDef.number(0, width: 22)]),
      BlockDef(shape: BlockShape.stack, label: 'Change', fields: [BlockFieldDef.dropdown(''), BlockFieldDef.label('By'), BlockFieldDef.number(1, width: 22)]),
      BlockDef(shape: BlockShape.reporter, label: '', fields: [BlockFieldDef.dropdown('my variable')]),
    ],
  ),
  BlockCategoryDef(
    key: 'objfn',
    name: "Object's Functions",
    color: _BlockColors.objFn,
    darkColor: _BlockColors.objFnD,
    blocks: [
      BlockDef(shape: BlockShape.stack, label: '', fields: [BlockFieldDef.question(), BlockFieldDef.label('to'), BlockFieldDef.dropdown('do something')]),
      BlockDef(shape: BlockShape.stack, label: '', fields: [BlockFieldDef.gear(), BlockFieldDef.question(), BlockFieldDef.label('to'), BlockFieldDef.dropdown('do something')]),
      BlockDef(shape: BlockShape.stack, label: 'if', fields: [BlockFieldDef.slot(width: 18), BlockFieldDef.label('return'), BlockFieldDef.slot(width: 18)]),
      BlockDef(shape: BlockShape.stack, label: 'return', fields: [BlockFieldDef.slot(width: 18)], rightNotch: false),
    ],
  ),
  BlockCategoryDef(
    key: 'otherobjfn',
    name: "Other objects' Functions",
    color: _BlockColors.otherObjFn,
    darkColor: _BlockColors.otherObjFnD,
    blocks: [
      BlockDef(shape: BlockShape.stack, label: 'call', fields: [BlockFieldDef.dropdown('Oliver'), BlockFieldDef.dropdown('doThing')]),
    ],
  ),
  BlockCategoryDef(
    key: 'ai',
    name: 'AI',
    color: _BlockColors.ai,
    darkColor: _BlockColors.aiD,
    blocks: [
      BlockDef(shape: BlockShape.stack, label: 'Predict', fields: [BlockFieldDef.dropdown('')]),
      BlockDef(shape: BlockShape.hat, label: 'On Prediction', fields: [BlockFieldDef.dropdown('')]),
    ],
  ),
];
