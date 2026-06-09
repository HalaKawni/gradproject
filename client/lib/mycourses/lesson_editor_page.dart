import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════
//  TEMPLATE DEFINITIONS
// ═══════════════════════════════════════════════════════════════

enum _Layout {
  blank,
  imageOverlapBlock,
  twoBlocks,
  floatingImages,
  threeColumns,
  chatBubbles,
  fullColor,
}

class _TemplateData {
  final String id;
  final String name;
  final _Layout layout;
  final Color color1;
  final Color color2;
  final Color color3;

  const _TemplateData({
    required this.id,
    required this.name,
    required this.layout,
    required this.color1,
    this.color2 = const Color(0xFFFFFFFF),
    this.color3 = const Color(0xFFFFFFFF),
  });
}

const _kTemplates = <_TemplateData>[
  _TemplateData(id: 'blank', name: 'Blank', layout: _Layout.blank, color1: Color(0xFFFFFFFF)),
  _TemplateData(id: 't1', name: 'Image + Blue', layout: _Layout.imageOverlapBlock, color1: Color(0xFFADE8F4)),
  _TemplateData(id: 't2', name: 'Image + Yellow', layout: _Layout.imageOverlapBlock, color1: Color(0xFFFFF59D)),
  _TemplateData(id: 't3', name: 'Full Blue + Image', layout: _Layout.imageOverlapBlock, color1: Color(0xFFB2EBF2), color2: Color(0xFFB2EBF2)),
  _TemplateData(id: 't4', name: 'Purple + Teal', layout: _Layout.twoBlocks, color1: Color(0xFFB39DDB), color2: Color(0xFF80CBC4)),
  _TemplateData(id: 't5', name: 'Blue + Yellow', layout: _Layout.twoBlocks, color1: Color(0xFFADE8F4), color2: Color(0xFFFFF59D)),
  _TemplateData(id: 't6', name: 'Two Floating Images', layout: _Layout.floatingImages, color1: Color(0xFFFFFFFF)),
  _TemplateData(id: 't7', name: 'Three Columns', layout: _Layout.threeColumns, color1: Color(0xFFFFF59D), color2: Color(0xFFADE8F4), color3: Color(0xFF80CBC4)),
  _TemplateData(id: 't8', name: 'Chat Bubbles', layout: _Layout.chatBubbles, color1: Color(0xFFADE8F4), color2: Color(0xFFFFF59D)),
  _TemplateData(id: 't9', name: 'Full Color', layout: _Layout.fullColor, color1: Color(0xFFB2EBF2)),
];

// ═══════════════════════════════════════════════════════════════
//  CANVAS ELEMENT MODEL
// ═══════════════════════════════════════════════════════════════

enum _ElemType { text, image, shape }
enum _ShapeKind { rect, oval, roundedRect }

class _CanvasElem {
  final String id;
  final _ElemType type;
  Offset pos;
  Size size;
  // text
  String text;
  double fontSize;
  Color textColor;
  bool? bold;
  bool? italic;
  bool? underline;
  bool? strikethrough;
  TextAlign? textAlign;
  String? fontFamily;
  // image
  Uint8List? bytes;
  // shape
  _ShapeKind shapeKind;
  Color shapeColor;

  _CanvasElem._({
    required this.id,
    required this.type,
    required this.pos,
    required this.size,
    this.text = '',
    this.fontSize = 28,
    this.textColor = Colors.black,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.textAlign = TextAlign.left,
    this.fontFamily = 'Nunito',
    this.bytes,
    this.shapeKind = _ShapeKind.rect,
    this.shapeColor = const Color(0xFF4A90D9),
  });

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  factory _CanvasElem.text({
    required Offset pos,
    required String text,
    required double fontSize,
    required Color color,
    bool bold = false,
    bool italic = false,
  }) =>
      _CanvasElem._(
        id: _newId(), type: _ElemType.text,
        pos: pos, size: const Size(260, 70),
        text: text, fontSize: fontSize, textColor: color, bold: bold, italic: italic,
      );

  factory _CanvasElem.image({required Offset pos, required Uint8List bytes}) =>
      _CanvasElem._(
        id: _newId(), type: _ElemType.image,
        pos: pos, size: const Size(200, 150),
        bytes: bytes,
      );

  factory _CanvasElem.shape({
    required Offset pos,
    required _ShapeKind kind,
    required Color color,
  }) =>
      _CanvasElem._(
        id: _newId(), type: _ElemType.shape,
        pos: pos, size: const Size(120, 80),
        shapeKind: kind, shapeColor: color,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'pos': {'dx': pos.dx, 'dy': pos.dy},
    'size': {'width': size.width, 'height': size.height},
    'text': text,
    'fontSize': fontSize,
    'textColor': textColor.toARGB32(),
    'bold': bold,
    'italic': italic,
    'underline': underline,
    'strikethrough': strikethrough,
    'textAlign': textAlign?.index,
    'fontFamily': fontFamily,
    'bytes': bytes != null ? base64Encode(bytes!) : null,
    'shapeKind': shapeKind.name,
    'shapeColor': shapeColor.toARGB32(),
  };
}

// ═══════════════════════════════════════════════════════════════
//  PALETTES
// ═══════════════════════════════════════════════════════════════

const _kPalette = <Color>[
  Colors.black, Colors.white,
  Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFF43A047),
  Color(0xFFFDD835), Color(0xFF8E24AA), Color(0xFFFF6D00),
  Color(0xFF00ACC1), Color(0xFFEC407A), Color(0xFF6D4C41), Color(0xFF546E7A),
];

const _kBgPalette = <Color>[
  Color(0xFFFFFFFF), Color(0xFFF5F7FA), Color(0xFFADE8F4), Color(0xFFFFF59D),
  Color(0xFFB2EBF2), Color(0xFFB39DDB), Color(0xFF80CBC4), Color(0xFFFFCCBC),
  Color(0xFFC8E6C9), Color(0xFFFFE0B2), Color(0xFFE1BEE7), Color(0xFF263238),
];

// ═══════════════════════════════════════════════════════════════
//  PAGE
// ═══════════════════════════════════════════════════════════════

class LessonEditorPage extends StatefulWidget {
  final String lessonTitle;
  final int lessonNumber;
  final List<Map<String, dynamic>> initialSlides;

  const LessonEditorPage({
    super.key,
    required this.lessonTitle,
    required this.lessonNumber,
    this.initialSlides = const [],
  });

  @override
  State<LessonEditorPage> createState() => _LessonEditorPageState();
}

const _kFontFamilies = ['Nunito', 'Montserrat', 'Roboto', 'Lobster', 'Dancing Script'];

class _LessonEditorPageState extends State<LessonEditorPage> {
  _TemplateData? _selectedTemplate;
  bool _hoveredBack = false;

  // Canvas state (for the currently active slide)
  final List<_CanvasElem> _elements = [];
  String? _selectedId;
  String? _editingId;
  Color? _bgColor;
  String _notes = '';
  final Map<String, TextEditingController> _textCtrls = {};
  final Map<String, FocusNode> _textFocusNodes = {};

  // Slides list — each entry is serialized slide data (or {} if not yet edited)
  List<Map<String, dynamic>> _slides = [{}];
  int _currentSlideIdx = 0;

  // AI chat panel
  bool _showAiPanel = false;
  final List<_AiMsg> _aiHistory = [];
  final TextEditingController _aiInputCtrl = TextEditingController();
  final ScrollController _aiScrollCtrl = ScrollController();
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSlides.isNotEmpty) {
      _slides = widget.initialSlides
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
      _currentSlideIdx = 0;
      if (_slides[0].isNotEmpty) _applySlideData(_slides[0]);
    }
  }

  // ── Serialize current canvas into _slides[_currentSlideIdx] ──
  void _saveCurrentSlide() {
    if (_selectedTemplate == null) return;
    _slides[_currentSlideIdx] = {
      'templateId': _selectedTemplate!.id,
      'bgColor': _bgColor?.toARGB32(),
      'elements': _elements.map((e) => e.toJson()).toList(),
    };
  }

  // ── Clear canvas state without calling setState ──
  void _clearCanvas() {
    for (final c in _textCtrls.values) c.dispose();
    for (final f in _textFocusNodes.values) f.dispose();
    _textCtrls.clear();
    _textFocusNodes.clear();
    _elements.clear();
    _selectedTemplate = null;
    _bgColor = null;
    _selectedId = null;
    _editingId = null;
    _notes = '';
  }

  // ── Load serialized slide data into canvas state ──
  void _applySlideData(Map<String, dynamic> data) {
    final templateId = data['templateId'] as String? ?? 'blank';
    _selectedTemplate = _kTemplates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => _kTemplates.first,
    );
    final bgColorVal = data['bgColor'] as int?;
    _bgColor = bgColorVal != null ? Color(bgColorVal) : null;

    final rawElems = (data['elements'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    for (final e in rawElems) {
      final type = e['type'] as String? ?? 'text';
      final dx = (e['pos']?['dx'] as num? ?? 0).toDouble();
      final dy = (e['pos']?['dy'] as num? ?? 0).toDouble();
      final w = (e['size']?['width'] as num? ?? 100).toDouble();
      final h = (e['size']?['height'] as num? ?? 50).toDouble();
      final id = e['id'] as String? ?? _CanvasElem._newId();

      _CanvasElem? elem;
      switch (type) {
        case 'text':
          elem = _CanvasElem._(
            id: id, type: _ElemType.text,
            pos: Offset(dx, dy), size: Size(w, h),
            text: e['text'] as String? ?? '',
            fontSize: (e['fontSize'] as num? ?? 28).toDouble(),
            textColor: Color(e['textColor'] as int? ?? 0xFF000000),
            bold: e['bold'] as bool?,
            italic: e['italic'] as bool?,
            underline: e['underline'] as bool?,
            strikethrough: e['strikethrough'] as bool?,
            textAlign: e['textAlign'] != null
                ? TextAlign.values[e['textAlign'] as int]
                : null,
            fontFamily: e['fontFamily'] as String?,
          );
          _textCtrls[id] = TextEditingController(text: elem.text);
          _textFocusNodes[id] = FocusNode();
          break;
        case 'image':
          final b64 = e['bytes'] as String?;
          if (b64 != null) {
            elem = _CanvasElem._(
              id: id, type: _ElemType.image,
              pos: Offset(dx, dy), size: Size(w, h),
              bytes: base64Decode(b64),
            );
          }
          break;
        case 'shape':
          elem = _CanvasElem._(
            id: id, type: _ElemType.shape,
            pos: Offset(dx, dy), size: Size(w, h),
            shapeKind: _ShapeKind.values.firstWhere(
              (k) => k.name == e['shapeKind'],
              orElse: () => _ShapeKind.rect,
            ),
            shapeColor: Color(e['shapeColor'] as int? ?? 0xFF4A90D9),
          );
          break;
      }
      if (elem != null) _elements.add(elem);
    }
  }

  void _switchToSlide(int idx) {
    if (idx == _currentSlideIdx) return;
    setState(() {
      _saveCurrentSlide();
      _clearCanvas();
      _currentSlideIdx = idx;
      if (_slides[idx].isNotEmpty) _applySlideData(_slides[idx]);
    });
  }

  void _addSlide() {
    setState(() {
      _saveCurrentSlide();
      _clearCanvas();
      _slides.add({});
      _currentSlideIdx = _slides.length - 1;
    });
  }

  void _deleteSlide(int idx) {
    if (_slides.length <= 1) return;
    setState(() {
      _slides.removeAt(idx);
      final newIdx = _currentSlideIdx >= _slides.length
          ? _slides.length - 1
          : _currentSlideIdx;
      _clearCanvas();
      _currentSlideIdx = newIdx;
      if (_slides[newIdx].isNotEmpty) _applySlideData(_slides[newIdx]);
    });
  }

  @override
  void dispose() {
    for (final c in _textCtrls.values) { c.dispose(); }
    for (final f in _textFocusNodes.values) { f.dispose(); }
    _aiInputCtrl.dispose();
    _aiScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildNavbar(),
          Expanded(
            child: _selectedTemplate == null
                ? _buildTemplatePicker()
                : _buildEditor(),
          ),
        ],
      ),
    );
  }

  // ── NAV BAR ──────────────────────────────────────────────────
  Widget _buildNavbar() {
    final isMobile = MediaQuery.of(context).size.width < 650;
    return SafeArea(
      bottom: false,
      child: Container(
        color: const Color.fromARGB(255, 252, 183, 199),
        height: 52,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_selectedTemplate != null) {
                  setState(() => _selectedTemplate = null);
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              _selectedTemplate == null
                  ? 'Lesson ${widget.lessonNumber}: ${widget.lessonTitle}'
                  : '${widget.lessonTitle} — ${_selectedTemplate!.name}',
              style: GoogleFonts.montserrat(
                color: const Color.fromARGB(255, 202, 97, 128),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_selectedTemplate != null)
              ElevatedButton.icon(
                onPressed: () {
                  _saveCurrentSlide();
                  final valid = _slides.where((s) => s.isNotEmpty).toList();
                  if (valid.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please design at least one slide.'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ));
                    return;
                  }
                  Navigator.of(context).pop(valid);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6DB84A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text('Save',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            const SizedBox(width: 16),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF4A7DBF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ── TEMPLATE PICKER ──────────────────────────────────────────
  Widget _buildTemplatePicker() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(40, 28, 40, 20),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose a Template',
                  style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2C3E50))),
              const SizedBox(height: 4),
              Text('Pick one of the layouts below to start building your lesson slide.',
                  style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF888888))),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(40, 28, 40, 40),
            child: Wrap(
              spacing: 28,
              runSpacing: 28,
              children: _kTemplates.map(_buildTemplateCard).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(_TemplateData t) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTemplate = t;
        _elements.clear();
        _bgColor = null;
        _selectedId = null;
      }),
      child: _TemplateCardHover(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 260,
                height: 163,
                child: t.id == 'blank'
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFCCCCCC), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.add_box_outlined,
                              color: Color(0xFFBBBBBB), size: 40),
                        ),
                      )
                    : Image.asset(
                        'assets/images/templates/templete${t.id.substring(1)}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: t.color1,
                          child: Center(
                            child: Text(t.name,
                                style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black54)),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(t.name,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF444444))),
            ),
          ],
        ),
      ),
    );
  }

  // ── SLIDES PANEL ─────────────────────────────────────────────
  Widget _buildSlidesPanel() {
    return Container(
      width: 120,
      color: const Color(0xFF2C2C3E),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: const Color(0xFF1E1E2D),
            child: Center(
              child: Text('SLIDES',
                  style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF888899),
                      letterSpacing: 1.5)),
            ),
          ),
          // Slide thumbnails
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _slides.length,
              itemBuilder: (ctx, idx) {
                final isCurrent = idx == _currentSlideIdx;
                final slideData = _slides[idx];
                return GestureDetector(
                  onTap: () => _switchToSlide(idx),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF4DD0C4)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: slideData.isNotEmpty
                                ? IgnorePointer(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: 800,
                                        height: 450,
                                        child: LessonSlideRenderer(
                                            slideData: slideData),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFF3A3A4E),
                                    child: Center(
                                      child: Icon(Icons.add,
                                          size: 18,
                                          color: Colors.white.withValues(
                                              alpha: 0.3)),
                                    ),
                                  ),
                          ),
                        ),
                        // Delete button (shown only when more than 1 slide)
                        if (_slides.length > 1)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _deleteSlide(idx),
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFE53935),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 10, color: Colors.white),
                              ),
                            ),
                          ),
                        // Slide number label
                        Positioned(
                          bottom: 3,
                          left: 4,
                          child: Text('${idx + 1}',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent
                                      ? const Color(0xFF4DD0C4)
                                      : Colors.white60)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Add slide button
          GestureDetector(
            onTap: _addSlide,
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A4E),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: const Color(0xFF4DD0C4).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 14, color: Color(0xFF4DD0C4)),
                  const SizedBox(width: 4),
                  Text('Add Slide',
                      style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4DD0C4))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SLIDE EDITOR ─────────────────────────────────────────────
  Widget _buildEditor() {
    return Stack(
      children: [
      Positioned.fill(child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        _buildSlidesPanel(),
        Expanded(child: Column(
        children: [
        // Back to templates bar
        Container(
          color: const Color(0xFFF0F0F0),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              MouseRegion(
                onEnter: (_) => setState(() => _hoveredBack = true),
                onExit: (_) => setState(() => _hoveredBack = false),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTemplate = null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _hoveredBack
                          ? const Color(0xFFE0E0E0)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.grid_view_rounded,
                          size: 16, color: Color(0xFF555555)),
                      const SizedBox(width: 6),
                      Text('Change Template',
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF555555))),
                    ]),
                  ),
                ),
              ),
              const Spacer(),
              if (_notes.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9C4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.note_alt_outlined,
                        size: 14, color: Color(0xFFFF8F00)),
                    const SizedBox(width: 4),
                    Text('Notes saved',
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF8F00))),
                  ]),
                ),
              const SizedBox(width: 12),
              Text('Lesson ${widget.lessonNumber}  ·  Slide 1',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF888888),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),

        // Text format bar — visible when a text element is selected
        Builder(builder: (ctx) {
          final sel = _selectedId;
          if (sel == null) return const SizedBox.shrink();
          final matches = _elements.where((e) => e.id == sel && e.type == _ElemType.text);
          if (matches.isEmpty) return const SizedBox.shrink();
          return _buildTextFormatBar(matches.first);
        }),

        // Canvas
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedId = null;
              _editingId = null;
            }),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: LayoutBuilder(
                      builder: (ctx, box) =>
                          _buildCanvas(box.maxWidth, box.maxHeight),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        _buildBottomToolbar(),
      ],
      )),   // close Column + Expanded
      ],
    )),     // close Row children + Positioned.fill(Row)
      if (_showAiPanel)
        Positioned(top: 0, right: 0, bottom: 0, child: _buildAiPanel()),
      ],
    );
  }

  Widget _buildCanvas(double cw, double ch) {
    return Stack(
      children: [
        // Background
        Positioned.fill(
          child: _selectedTemplate!.id == 'blank'
              ? Container(color: _bgColor ?? Colors.white)
              : Stack(children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/templates/templete${_selectedTemplate!.id.substring(1)}.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: _bgColor ?? const Color(0xFFF0F0F0)),
                    ),
                  ),
                  if (_bgColor != null)
                    Positioned.fill(
                      child: Container(
                          color: _bgColor!.withValues(alpha: 0.35)),
                    ),
                ]),
        ),

        // Elements
        ..._elements.map((e) => _buildElemWidget(e, cw, ch)),

        // Selection controls rendered at canvas level so hit-test is never clipped
        ..._buildTextSelectionOverlay(),
      ],
    );
  }

  List<Widget> _buildTextSelectionOverlay() {
    if (_selectedId == null) return [];
    final matches = _elements.where(
        (e) => e.id == _selectedId && e.type == _ElemType.text);
    if (matches.isEmpty) return [];
    final elem = matches.first;

    return [
      // ── Delete button ──────────────────────────────────────
      Positioned(
        left: elem.pos.dx + elem.size.width - 12,
        top: elem.pos.dy - 14,
        child: GestureDetector(
          onTap: () => setState(() {
            _elements.removeWhere((e) => e.id == elem.id);
            _textCtrls.remove(elem.id)?.dispose();
            _textFocusNodes.remove(elem.id)?.dispose();
            _selectedId = null;
            _editingId = null;
          }),
          child: Container(
            width: 26, height: 26,
            decoration: const BoxDecoration(
                color: Color(0xFFE53935), shape: BoxShape.circle),
            child: const Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ),
      ),
      // ── Left resize handle ─────────────────────────────────
      Positioned(
        left: elem.pos.dx - 7,
        top: elem.pos.dy + 4,
        child: _ResizeHandle(
          cursor: SystemMouseCursors.resizeLeftRight,
          onDrag: (d) => setState(() {
            final nw = (elem.size.width - d.delta.dx).clamp(80.0, 700.0);
            elem.pos = Offset(elem.pos.dx + elem.size.width - nw, elem.pos.dy);
            elem.size = Size(nw, elem.size.height);
          }),
        ),
      ),
      // ── Right resize handle ────────────────────────────────
      Positioned(
        left: elem.pos.dx + elem.size.width - 5,
        top: elem.pos.dy + 4,
        child: _ResizeHandle(
          cursor: SystemMouseCursors.resizeLeftRight,
          onDrag: (d) => setState(() {
            elem.size = Size(
              (elem.size.width + d.delta.dx).clamp(80.0, 700.0),
              elem.size.height,
            );
          }),
        ),
      ),
    ];
  }

  Widget _buildElemWidget(_CanvasElem elem, double cw, double ch) {
    if (elem.type == _ElemType.text) {
      return _buildTextElem(elem, cw, ch);
    }

    final sel = _selectedId == elem.id;

    Widget inner;
    switch (elem.type) {
      case _ElemType.text:
        inner = const SizedBox.shrink(); // handled above
        break;
      case _ElemType.image:
        inner = Image.memory(elem.bytes!,
            fit: BoxFit.contain,
            width: elem.size.width,
            height: elem.size.height);
        break;
      case _ElemType.shape:
        inner = Container(
          decoration: BoxDecoration(
            color: elem.shapeColor,
            borderRadius: elem.shapeKind == _ShapeKind.roundedRect
                ? BorderRadius.circular(16)
                : null,
            shape: elem.shapeKind == _ShapeKind.oval
                ? BoxShape.circle
                : BoxShape.rectangle,
          ),
        );
        break;
    }

    return Positioned(
      left: elem.pos.dx,
      top: elem.pos.dy,
      child: GestureDetector(
        onTap: () {
          if (_selectedId != elem.id) {
            setState(() { _selectedId = elem.id; _editingId = null; });
          }
        },
        onPanUpdate: (d) {
          setState(() {
            elem.pos = Offset(
              (elem.pos.dx + d.delta.dx).clamp(0.0, cw - elem.size.width),
              (elem.pos.dy + d.delta.dy).clamp(0.0, ch - elem.size.height),
            );
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: elem.size.width,
              height: elem.size.height,
              decoration: sel
                  ? BoxDecoration(
                      border: Border.all(color: const Color(0xFF4A90D9), width: 2),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: inner,
            ),
            if (sel) ...[
              Positioned(
                top: -14, right: -14,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _elements.removeWhere((e) => e.id == elem.id);
                    _selectedId = null;
                  }),
                  child: Container(
                    width: 26, height: 26,
                    decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
              Positioned(
                top: -14, left: -14,
                child: GestureDetector(
                  onTap: () => setState(() {
                    final e = _elements.firstWhere((e) => e.id == elem.id);
                    _elements..remove(e)..add(e);
                  }),
                  child: Container(
                    width: 26, height: 26,
                    decoration: const BoxDecoration(color: Color(0xFF4A90D9), shape: BoxShape.circle),
                    child: const Icon(Icons.flip_to_front, color: Colors.white, size: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── TEXT STYLE HELPER ────────────────────────────────────────
  TextStyle _makeTextStyle(_CanvasElem elem) {
    final w = (elem.bold ?? false) ? FontWeight.w800 : FontWeight.w600;
    final s = (elem.italic ?? false) ? FontStyle.italic : FontStyle.normal;
    final deco = TextDecoration.combine([
      if (elem.underline ?? false) TextDecoration.underline,
      if (elem.strikethrough ?? false) TextDecoration.lineThrough,
    ]);
    switch (elem.fontFamily ?? 'Nunito') {
      case 'Montserrat': return GoogleFonts.montserrat(fontSize: elem.fontSize, color: elem.textColor, fontWeight: w, fontStyle: s, decoration: deco, decorationColor: elem.textColor);
      case 'Roboto':     return GoogleFonts.roboto(fontSize: elem.fontSize, color: elem.textColor, fontWeight: w, fontStyle: s, decoration: deco, decorationColor: elem.textColor);
      case 'Lobster':    return GoogleFonts.lobster(fontSize: elem.fontSize, color: elem.textColor, fontWeight: w, fontStyle: s, decoration: deco, decorationColor: elem.textColor);
      case 'Dancing Script': return GoogleFonts.dancingScript(fontSize: elem.fontSize, color: elem.textColor, fontWeight: w, fontStyle: s, decoration: deco, decorationColor: elem.textColor);
      default:           return GoogleFonts.nunito(fontSize: elem.fontSize, color: elem.textColor, fontWeight: w, fontStyle: s, decoration: deco, decorationColor: elem.textColor);
    }
  }

  Widget _buildTextElem(_CanvasElem elem, double cw, double ch) {
    final isSel = _selectedId == elem.id;
    final isEdit = _editingId == elem.id;
    final ts = _makeTextStyle(elem);

    final inner = isEdit
        ? TextField(
            controller: _textCtrls[elem.id],
            focusNode: _textFocusNodes[elem.id],
            style: ts,
            textAlign: elem.textAlign ?? TextAlign.left,
            cursorColor: const Color(0xFF4A90D9),
            decoration: const InputDecoration(
              border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
            ),
            onChanged: (v) => elem.text = v,
            maxLines: null, minLines: 1,
          )
        : Text(
            elem.text.isEmpty ? 'Your text here' : elem.text,
            textAlign: elem.textAlign ?? TextAlign.left,
            style: ts.copyWith(
              color: elem.text.isEmpty ? Colors.grey.shade400 : elem.textColor,
            ),
          );

    return Positioned(
      left: elem.pos.dx,
      top: elem.pos.dy,
      child: GestureDetector(
        onTap: () {
          if (!isSel) {
            // First tap: select only — lets user drag before typing
            setState(() { _selectedId = elem.id; _editingId = null; });
          } else if (!isEdit) {
            // Second tap on already-selected: enter edit mode
            setState(() => _editingId = elem.id);
            WidgetsBinding.instance.addPostFrameCallback((_) =>
                _textFocusNodes[elem.id]?.requestFocus());
          }
        },
        onPanUpdate: isEdit ? null : (d) => setState(() {
          elem.pos = Offset(
            (elem.pos.dx + d.delta.dx).clamp(0.0, cw - 40),
            (elem.pos.dy + d.delta.dy).clamp(0.0, ch - 40),
          );
        }),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: elem.size.width,
              padding: const EdgeInsets.all(6),
              decoration: (isSel || isEdit)
                  ? BoxDecoration(
                      border: Border.all(color: const Color(0xFF4A90D9), width: 2),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: inner,
            ),
            // (delete + resize handles are rendered at canvas level so hit-test works)
          ],
        ),
      ),
    );
  }

  // ── TEXT FORMAT BAR ───────────────────────────────────────────
  Widget _buildTextFormatBar(_CanvasElem elem) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Font family
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFDDDDDD)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: elem.fontFamily ?? 'Nunito',
                  isDense: true,
                  style: GoogleFonts.nunito(fontSize: 13, color: Colors.black87),
                  items: _kFontFamilies.map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f, style: GoogleFonts.nunito(fontSize: 13)),
                  )).toList(),
                  onChanged: (f) { if (f != null) setState(() => elem.fontFamily = f); },
                ),
              ),
            ),
            const _FmtDivider(),

            // Font size
            _FmtBtn(onTap: () => setState(() => elem.fontSize = (elem.fontSize - 2).clamp(8, 120)), child: const Icon(Icons.remove, size: 14)),
            const SizedBox(width: 4),
            SizedBox(width: 32, child: Center(child: Text(elem.fontSize.round().toString(), style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 4),
            _FmtBtn(onTap: () => setState(() => elem.fontSize = (elem.fontSize + 2).clamp(8, 120)), child: const Icon(Icons.add, size: 14)),
            const _FmtDivider(),

            // B I U S
            _FmtBtn(active: elem.bold ?? false,          onTap: () => setState(() => elem.bold = !(elem.bold ?? false)),                   child: Text('B', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 14))),
            const SizedBox(width: 4),
            _FmtBtn(active: elem.italic ?? false,        onTap: () => setState(() => elem.italic = !(elem.italic ?? false)),               child: Text('I', style: GoogleFonts.nunito(fontStyle: FontStyle.italic, fontWeight: FontWeight.w700, fontSize: 14))),
            const SizedBox(width: 4),
            _FmtBtn(active: elem.underline ?? false,     onTap: () => setState(() => elem.underline = !(elem.underline ?? false)),         child: Text('U', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, decoration: TextDecoration.underline))),
            const SizedBox(width: 4),
            _FmtBtn(active: elem.strikethrough ?? false, onTap: () => setState(() => elem.strikethrough = !(elem.strikethrough ?? false)), child: Text('S', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, decoration: TextDecoration.lineThrough))),
            const _FmtDivider(),

            // Alignment
            _FmtBtn(active: elem.textAlign == TextAlign.left,   onTap: () => setState(() => elem.textAlign = TextAlign.left),   child: const Icon(Icons.format_align_left,   size: 16)),
            const SizedBox(width: 4),
            _FmtBtn(active: elem.textAlign == TextAlign.center, onTap: () => setState(() => elem.textAlign = TextAlign.center), child: const Icon(Icons.format_align_center, size: 16)),
            const SizedBox(width: 4),
            _FmtBtn(active: elem.textAlign == TextAlign.right,  onTap: () => setState(() => elem.textAlign = TextAlign.right),  child: const Icon(Icons.format_align_right,  size: 16)),
            const _FmtDivider(),

            // Color swatches
            ..._kPalette.map((c) => Padding(
              padding: const EdgeInsets.only(right: 5),
              child: GestureDetector(
                onTap: () => setState(() => elem.textColor = c),
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: Border.all(
                      color: elem.textColor == c ? const Color(0xFF4A90D9) : const Color(0xFFCCCCCC),
                      width: elem.textColor == c ? 2.5 : 1,
                    ),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ToolbarBtn(
              icon: Icons.title_rounded, label: 'Text', onTap: _onAddText),
          const SizedBox(width: 12),
          _ToolbarBtn(
              icon: Icons.image_outlined, label: 'Image', onTap: _onAddImage),
          const SizedBox(width: 12),
          _ToolbarBtn(
              icon: Icons.color_lens_outlined,
              label: 'Color',
              onTap: _onPickBgColor),
          const SizedBox(width: 12),
          _ToolbarBtn(
              icon: Icons.add_box_outlined, label: 'Shape', onTap: _onAddShape),
          const SizedBox(width: 12),
          _ToolbarBtn(
              icon: Icons.note_alt_outlined, label: 'Notes', onTap: _onNotes),
          const SizedBox(width: 12),
          _ToolbarBtn(
              icon: Icons.auto_awesome_rounded,
              label: 'AI',
              onTap: () => setState(() => _showAiPanel = !_showAiPanel)),
        ],
      ),
    );
  }

  // ── AI CHAT PANEL ────────────────────────────────────────────

  Widget _buildAiPanel() {
    return Container(
      width: 340,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(-4, 0))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFC87A0), Color(0xFFB48EE0)],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('AI Assistant',
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showAiPanel = false),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: _aiHistory.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 48, color: Color(0xFFDDDDDD)),
                          const SizedBox(height: 12),
                          Text('Ask me to write slide content!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                  fontSize: 14, color: const Color(0xFFAAAAAA))),
                          const SizedBox(height: 6),
                          Text('e.g. "Write an intro about the internet"',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                  fontSize: 12, color: const Color(0xFFCCCCCC))),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _aiScrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: _aiHistory.length,
                    itemBuilder: (ctx, i) => _buildAiMessage(_aiHistory[i]),
                  ),
          ),

          // Loading indicator
          if (_aiLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(
                    backgroundColor: Color(0xFFEEEEEE),
                    valueColor: AlwaysStoppedAnimation(Color(0xFFFC87A0)),
                  )),
            ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _aiInputCtrl,
                    style: GoogleFonts.nunito(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ask for lesson content…',
                      hintStyle: GoogleFonts.nunito(fontSize: 13, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _onSendAiMessage(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _onSendAiMessage,
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFFFC87A0), Color(0xFFB48EE0)]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiMessage(_AiMsg msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFFFC87A0), Color(0xFFB48EE0)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 14),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFFFC87A0)
                        : const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: isUser ? Colors.white : const Color(0xFF333333),
                    ),
                  ),
                ),
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: () {
                        final elem = _CanvasElem.text(
                          pos: const Offset(60, 80),
                          text: msg.text,
                          fontSize: 20,
                          color: Colors.black87,
                        );
                        _textCtrls[elem.id] = TextEditingController(text: msg.text);
                        _textFocusNodes[elem.id] = FocusNode();
                        setState(() {
                          _elements.add(elem);
                          _selectedId = elem.id;
                          _editingId = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF4FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF4A90D9)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.add_circle_outline,
                              size: 13, color: Color(0xFF4A90D9)),
                          const SizedBox(width: 4),
                          Text('Add to slide',
                              style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF4A90D9))),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSendAiMessage() async {
    final text = _aiInputCtrl.text.trim();
    if (text.isEmpty || _aiLoading) return;

    _aiInputCtrl.clear();
    setState(() {
      _aiHistory.add(_AiMsg(isUser: true, text: text));
      _aiLoading = true;
    });
    _scrollAiToBottom();

    // Send all but the last message (the one we just added) as history
    final history = _aiHistory.length > 1
        ? _aiHistory
            .sublist(0, _aiHistory.length - 1)
            .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
            .toList()
        : <Map<String, String>>[];

    final reply = await ApiService.chatWithAI(
      message: text,
      lessonTitle: widget.lessonTitle,
      lessonNumber: widget.lessonNumber,
      history: history,
    );

    if (!mounted) return;
    setState(() {
      _aiHistory.add(_AiMsg(
        isUser: false,
        text: reply ?? 'Sorry, I could not generate a response. Please try again.',
      ));
      _aiLoading = false;
    });
    _scrollAiToBottom();
  }

  void _scrollAiToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_aiScrollCtrl.hasClients) {
        _aiScrollCtrl.animateTo(
          _aiScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── TOOLBAR ACTIONS ──────────────────────────────────────────

  void _onAddText() {
    final elem = _CanvasElem.text(
      pos: const Offset(60, 60),
      text: '',
      fontSize: 28,
      color: Colors.black,
    );
    _textCtrls[elem.id] = TextEditingController();
    _textFocusNodes[elem.id] = FocusNode();
    setState(() {
      _elements.add(elem);
      _selectedId = elem.id;
      _editingId = null; // select only — drag to position, then click to type
    });
  }

  Future<void> _onAddImage() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.first.bytes != null) {
      setState(() => _elements.add(_CanvasElem.image(
            pos: const Offset(60, 60),
            bytes: result.files.first.bytes!,
          )));
    }
  }

  void _onPickBgColor() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Background Color',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800, fontSize: 18)),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Clear / no tint
            GestureDetector(
              onTap: () {
                setState(() => _bgColor = null);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.not_interested,
                    color: Colors.grey.shade400, size: 20),
              ),
            ),
            ..._kBgPalette.map((c) => GestureDetector(
                  onTap: () {
                    setState(() => _bgColor = c);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _bgColor == c
                            ? const Color(0xFF4A90D9)
                            : Colors.grey.shade300,
                        width: _bgColor == c ? 2.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4)
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _onAddShape() {
    _ShapeKind kind = _ShapeKind.rect;
    Color color = const Color(0xFF4A90D9);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Add Shape',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w800, fontSize: 18)),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ShapePicker(
                      label: 'Rectangle',
                      icon: Icons.rectangle_outlined,
                      selected: kind == _ShapeKind.rect,
                      onTap: () => setS(() => kind = _ShapeKind.rect),
                    ),
                    const SizedBox(width: 12),
                    _ShapePicker(
                      label: 'Oval',
                      icon: Icons.circle_outlined,
                      selected: kind == _ShapeKind.oval,
                      onTap: () => setS(() => kind = _ShapeKind.oval),
                    ),
                    const SizedBox(width: 12),
                    _ShapePicker(
                      label: 'Rounded',
                      icon: Icons.rounded_corner,
                      selected: kind == _ShapeKind.roundedRect,
                      onTap: () => setS(() => kind = _ShapeKind.roundedRect),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Color',
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kPalette
                      .map((c) => GestureDetector(
                            onTap: () => setS(() => color = c),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: color == c
                                      ? const Color(0xFF4A90D9)
                                      : const Color(0xFFCCCCCC),
                                  width: color == c ? 2.5 : 1,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90D9),
                  foregroundColor: Colors.white),
              onPressed: () {
                setState(() => _elements.add(
                    _CanvasElem.shape(pos: const Offset(80, 80), kind: kind, color: color)));
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _onNotes() {
    final ctrl = TextEditingController(text: _notes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Speaker Notes',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800, fontSize: 18)),
        content: SizedBox(
          width: 420,
          height: 220,
          child: TextField(
            controller: ctrl,
            maxLines: null,
            expands: true,
            style: GoogleFonts.nunito(fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Add your speaker notes here...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90D9),
                foregroundColor: Colors.white),
            onPressed: () {
              setState(() => _notes = ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════

class _ShapePicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ShapePicker({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F4FD) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF4A90D9) : const Color(0xFFE0E0E0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 26,
                color: selected
                    ? const Color(0xFF4A90D9)
                    : const Color(0xFF555555)),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? const Color(0xFF4A90D9)
                        : const Color(0xFF555555))),
          ],
        ),
      ),
    );
  }
}

class _TemplateCardHover extends StatefulWidget {
  final Widget child;
  const _TemplateCardHover({required this.child});

  @override
  State<_TemplateCardHover> createState() => _TemplateCardHoverState();
}

class _TemplateCardHoverState extends State<_TemplateCardHover> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color:
              _hovered ? const Color(0xFFE8F4FD) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? const Color(0xFF4A90D9) : Colors.transparent,
            width: 2,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                      color: const Color(0xFF4A90D9).withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}

class _ToolbarBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolbarBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  State<_ToolbarBtn> createState() => _ToolbarBtnState();
}

class _ToolbarBtnState extends State<_ToolbarBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFFE8F4FD)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF4A90D9)
                  : const Color(0xFFE0E0E0),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon,
                size: 18,
                color: _hovered
                    ? const Color(0xFF4A90D9)
                    : const Color(0xFF555555)),
            const SizedBox(width: 6),
            Text(widget.label,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _hovered
                        ? const Color(0xFF4A90D9)
                        : const Color(0xFF555555))),
          ]),
        ),
      ),
    );
  }
}

class _FmtBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool active;
  const _FmtBtn({required this.child, required this.onTap, this.active = false});

  @override
  State<_FmtBtn> createState() => _FmtBtnState();
}

class _FmtBtnState extends State<_FmtBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlight = widget.active || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: highlight ? const Color(0xFFE8F4FD) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: highlight ? const Color(0xFF4A90D9) : const Color(0xFFDDDDDD),
              width: widget.active ? 2 : 1,
            ),
          ),
          child: IconTheme(
            data: IconThemeData(
              size: 14,
              color: highlight ? const Color(0xFF4A90D9) : const Color(0xFF444444),
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 14,
                color: highlight ? const Color(0xFF4A90D9) : const Color(0xFF444444),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  final void Function(DragUpdateDetails) onDrag;
  final MouseCursor cursor;
  const _ResizeHandle(
      {required this.onDrag, this.cursor = SystemMouseCursors.resizeLeftRight});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        onPanUpdate: onDrag,
        child: Container(
          width: 12,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFF4A90D9), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FmtDivider extends StatelessWidget {
  const _FmtDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFDDDDDD),
    );
  }
}

class _AiMsg {
  final bool isUser;
  final String text;
  _AiMsg({required this.isUser, required this.text});
}

// ═══════════════════════════════════════════════════════════════
//  PUBLIC SLIDE RENDERER — used by CustomCourseViewerPage
// ═══════════════════════════════════════════════════════════════

class LessonSlideRenderer extends StatelessWidget {
  final Map<String, dynamic> slideData;
  const LessonSlideRenderer({super.key, required this.slideData});

  @override
  Widget build(BuildContext context) {
    final templateId = slideData['templateId'] as String? ?? 'blank';
    final bgColorVal = slideData['bgColor'] as int?;
    final bgColor = bgColorVal != null ? Color(bgColorVal) : null;
    final rawElems = (slideData['elements'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return Stack(
      children: [
        _buildBg(templateId, bgColor),
        ...rawElems.map(_buildElem),
      ],
    );
  }

  Widget _buildBg(String templateId, Color? bgColor) {
    if (templateId == 'blank') {
      return Positioned.fill(child: Container(color: bgColor ?? Colors.white));
    }
    final num = templateId.substring(1);
    return Positioned.fill(
      child: Stack(children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/templates/templete$num.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Container(color: bgColor ?? const Color(0xFFF0F0F0)),
          ),
        ),
        if (bgColor != null)
          Positioned.fill(
              child: Container(color: bgColor.withValues(alpha: 0.35))),
      ]),
    );
  }

  Widget _buildElem(Map<String, dynamic> e) {
    final type = e['type'] as String? ?? 'text';
    final dx = (e['pos']?['dx'] as num? ?? 0).toDouble();
    final dy = (e['pos']?['dy'] as num? ?? 0).toDouble();
    final w = (e['size']?['width'] as num? ?? 100).toDouble();
    final h = (e['size']?['height'] as num? ?? 50).toDouble();

    Widget inner;
    switch (type) {
      case 'image':
        final b64 = e['bytes'] as String?;
        inner = b64 != null
            ? Image.memory(base64Decode(b64),
                width: w, height: h, fit: BoxFit.contain)
            : Container(width: w, height: h, color: Colors.grey[200]);
        break;
      case 'shape':
        final colorVal = e['shapeColor'] as int? ?? 0xFF4A90D9;
        final kind = e['shapeKind'] as String? ?? 'rect';
        inner = Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Color(colorVal),
            borderRadius:
                kind == 'roundedRect' ? BorderRadius.circular(16) : null,
            shape: kind == 'oval' ? BoxShape.circle : BoxShape.rectangle,
          ),
        );
        break;
      default: // text
        inner = _buildTextWidget(e, w, h);
    }

    // Text elements: only constrain width so wrapped text is never clipped.
    // Images/shapes keep their exact height.
    final sized = type == 'text'
        ? SizedBox(width: w, child: inner)
        : SizedBox(width: w, height: h, child: inner);
    return Positioned(left: dx, top: dy, child: sized);
  }

  Widget _buildTextWidget(Map<String, dynamic> e, double w, double h) {
    final text = e['text'] as String? ?? '';
    final fontSize = (e['fontSize'] as num? ?? 28).toDouble();
    final colorVal = e['textColor'] as int? ?? 0xFF000000;
    final bold = e['bold'] as bool? ?? false;
    final italic = e['italic'] as bool? ?? false;
    final underline = e['underline'] as bool? ?? false;
    final strikethrough = e['strikethrough'] as bool? ?? false;
    final textAlignIdx = e['textAlign'] as int?;
    final fontFamily = e['fontFamily'] as String? ?? 'Nunito';

    final textAlign = (textAlignIdx != null &&
            textAlignIdx >= 0 &&
            textAlignIdx < TextAlign.values.length)
        ? TextAlign.values[textAlignIdx]
        : TextAlign.left;

    final decorations = <TextDecoration>[
      if (underline) TextDecoration.underline,
      if (strikethrough) TextDecoration.lineThrough,
    ];

    final baseStyle = TextStyle(
      fontSize: fontSize,
      color: Color(colorVal),
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: decorations.isEmpty
          ? TextDecoration.none
          : TextDecoration.combine(decorations),
    );

    TextStyle style;
    try {
      style = GoogleFonts.getFont(fontFamily, textStyle: baseStyle);
    } catch (_) {
      style = baseStyle;
    }

    return Text(text, style: style, textAlign: textAlign, maxLines: null);
  }
}
