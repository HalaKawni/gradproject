import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'digital_wordsearch_page.dart';
import '../services/api_service.dart';
import 'cyber_match_game.dart';
import 'lesson_slide_texts.dart';


// ===========================================================================
//  THEME
// ===========================================================================
class _WPColors {
  static const cream     = Color(0xFFFFF6E4);
  static const cream2    = Color(0xFFFFEFD1);
  static const paper     = Color(0xFFFFFDF6);
  static const ink       = Color(0xFF28204A);
  static const inkSoft   = Color(0xFF5B5380);
  static const sky       = Color(0xFF6BC5FF);
  static const skyDeep   = Color(0xFF2E8FD0);
  static const skyDark   = Color(0xFF0E3F66);
  static const skyShadow = Color(0xFF1B5C8E);
  static const mint      = Color(0xFF7BD8B5);
  static const mintLight = Color(0xFFA8E8C9);
  static const mintDeep  = Color(0xFF2DA47A);
  static const coral     = Color(0xFFFF8A77);
  static const coralDeep = Color(0xFFE25A45);
  static const sun       = Color(0xFFFFC83D);
  static const sunLight  = Color(0xFFFFE48A);
  static const sunDeep   = Color(0xFFE0A300);
  static const grass     = Color(0xFF9BD96B);
  static const grassDeep = Color(0xFF5DA13A);
  static const tealBg    = Color(0xFF5FB5A8);
  static const tealBg2   = Color(0xFF4A9A8E);
  static const headerBg  = Color(0xFF2B2342);
  static const purple    = Color(0xFF7B5DC2);
  static const purpleDeep= Color(0xFF5E45A0);
}

// ===========================================================================
//  DATA MODELS
// ===========================================================================
class _Blank {
  final String id;
  final String answer;
  String? filledWith;
  _Blank({required this.id, required this.answer, this.filledWith});
}

class _SentencePart {
  final String? text;
  final _Blank? blank;
  _SentencePart.text(this.text) : blank = null;
  _SentencePart.blank(this.blank) : text = null;
  bool get isBlank => blank != null;
}

class _Sentence {
  final List<_SentencePart> parts;
  _Sentence(this.parts);
}

// ===========================================================================
//  PAGE
// ===========================================================================
class DigitalReviewPage extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final VoidCallback? onChainFinished;
  const DigitalReviewPage({super.key, required this.lesson, this.onChainFinished});

  @override
  State<DigitalReviewPage> createState() => _DigitalReviewPageState();
}

class _DigitalReviewPageState extends State<DigitalReviewPage>
    with TickerProviderStateMixin {

  late List<_Sentence> _sentences;

  List<String> _allWords = [
    'software', 'Cc:', 'To:', 'keywords',
    'hardware', 'search engine', 'inbox folder', 'drafts folder',
    'YouTube', 'browser', 'webpages', 'monitor',
  ];
  late List<String> _bank;

  final Map<String, String> _filled  = {};
  final Set<String>  _correct = {};
  String? _wrongKey;
  String? _sparkleKey;
  String? _selectedChip;
  String? _dragTargetKey;

  int _score = 0;
  bool _done  = false;
  bool _isLoading = false;
  String _hintMsg = 'Select a word below, then tap a blank — or drag!';

  late final AnimationController _confettiCtrl;
  late final AnimationController _bounceCtrl;

  int get _total => _sentences.fold(
      0, (s, sen) => s + sen.parts.where((p) => p.isBlank).length);

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _initSentences();
    _bank = List.from(_allWords)..shuffle(math.Random());
  }

  Future<void> _loadAiSentences() async {
    setState(() => _isLoading = true);
    final lessonNumber = widget.lesson['number'] as int;
    final slideTexts = LessonSlideTexts.forLesson(lessonNumber);
    if (slideTexts.isEmpty) { setState(() => _isLoading = false); return; }

    final data = await ApiService.generateFillBlanks(
      lessonNumber: lessonNumber,
      slideTexts: slideTexts,
    );
    if (!mounted) return;

    final rawSentences = List<String>.from(data['sentences'] ?? []);
    final distractors  = List<String>.from(data['distractors'] ?? []);

    if (rawSentences.length >= 2) {
      final blankRe = RegExp(r'\{\{([^}]+)\}\}');
      int blankCounter = 0;

      final newSentences = rawSentences.map((raw) {
        final parts = <_SentencePart>[];
        int last = 0;
        for (final m in blankRe.allMatches(raw)) {
          if (m.start > last) parts.add(_SentencePart.text(raw.substring(last, m.start)));
          parts.add(_SentencePart.blank(_Blank(id: 'ai_b${blankCounter++}', answer: m.group(1)!.trim())));
          last = m.end;
        }
        if (last < raw.length) parts.add(_SentencePart.text(raw.substring(last)));
        return _Sentence(parts);
      }).toList();

      final answers = newSentences
          .expand((s) => s.parts.where((p) => p.isBlank).map((p) => p.blank!.answer))
          .toList();
      final newBank = [...answers, ...distractors]..shuffle(math.Random());

      setState(() {
        _sentences = newSentences;
        _allWords.clear();
        _allWords.addAll(newBank);
        _bank = List.from(newBank);
        _filled.clear();
        _correct.clear();
        _wrongKey = null;
        _sparkleKey = null;
        _selectedChip = null;
        _score = 0;
        _done = false;
        _hintMsg = 'Select a word below, then tap a blank — or drag!';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✨ New sentences generated from lesson!',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: _WPColors.grassDeep,
          duration: const Duration(seconds: 2),
        ));
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('⚠️ AI unavailable — using default sentences.',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: _WPColors.coralDeep,
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }

  void _initSentences() {
    _sentences = [
      _Sentence([
        _SentencePart.text("I started writing an email, but now I can't find it. I should go to the "),
        _SentencePart.blank(_Blank(id: 'b1', answer: 'drafts folder')),
        _SentencePart.text(" to find it."),
      ]),
      _Sentence([
        _SentencePart.text(" The main recipients of my email will be in the "),
        _SentencePart.blank(_Blank(id: 'b2', answer: 'To:')),
        _SentencePart.text(", while the others who I don't expect a reply from will be in the "),
        _SentencePart.blank(_Blank(id: 'b3', answer: 'Cc:')),
        _SentencePart.text("."),
      ]),
      _Sentence([
        _SentencePart.text("Computer "),
        _SentencePart.blank(_Blank(id: 'b4', answer: 'hardware')),
        _SentencePart.text(" includes: mouse, keyboard, "),
        _SentencePart.blank(_Blank(id: 'b5', answer: 'monitor')),
        _SentencePart.text(" and printer."),
      ]),
      _Sentence([
        _SentencePart.text("When doing research on the internet, I enter "),
        _SentencePart.blank(_Blank(id: 'b6', answer: 'keywords')),
        _SentencePart.text(" into a "),
        _SentencePart.blank(_Blank(id: 'b7', answer: 'search engine')),
        _SentencePart.text("."),
      ]),
      _Sentence([
        _SentencePart.text(" Websites contain many "),
        _SentencePart.blank(_Blank(id: 'b8', answer: 'webpages')),
        _SentencePart.text(", and they are viewed in a "),
        _SentencePart.blank(_Blank(id: 'b9', answer: 'browser')),
        _SentencePart.text("."),
      ]),
    ];
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  _Blank? _findBlank(String id) {
    for (final s in _sentences) {
      for (final p in s.parts) {
        if (p.isBlank && p.blank!.id == id) return p.blank;
      }
    }
    return null;
  }

  void _tryPlace(String blankId, String word) {
    final blank = _findBlank(blankId);
    if (blank == null || _correct.contains(blankId)) return;

    final isRight = word == blank.answer;
    setState(() {
      _bank.remove(word);
      _filled[blankId] = word;
      _selectedChip = null;
      if (isRight) {
        _correct.add(blankId);
        _sparkleKey = blankId;
        _score++;
        _hintMsg = _encouragement();
      } else {
        _wrongKey = blankId;
        _hintMsg = 'Not quite — try a different word!';
      }
    });

    if (isRight) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() => _sparkleKey = null);
        if (_correct.length == _total && !_done) {
    _bounceCtrl.forward(from: 0);
    _confettiCtrl.forward(from: 0);
    setState(() { _done = true; _hintMsg = 'You did it! 🎉'; });
    // Save score to backend
    final lessonNumber = widget.lesson['number'] as int;
    ApiService.saveFillBlanksScore(
      gameId: 'digital-literacy',
      lessonNumber: lessonNumber,
      correct: _correct.length,
      total: _total,
    );
  }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _filled.remove(blankId);
          _bank.add(word);
          _wrongKey = null;
        });
      });
    }
  }

  String _encouragement() {
    const msgs = ['Nice!', 'Great pick!', 'You got it!', 'Spot on!', 'Boom — correct!'];
    return msgs[math.Random().nextInt(msgs.length)];
  }

void _giveHint() {
  _Blank? next;
  for (final s in _sentences) {
    for (final p in s.parts) {
      if (p.isBlank && !_correct.contains(p.blank!.id)) {
        next = p.blank;
        break;
      }
    }
    if (next != null) break;
  }
  if (next == null) return;
  setState(() => _hintMsg = 'Try "${next!.answer}" 👀');
  Future.delayed(const Duration(milliseconds: 2400), () {
    if (mounted && !_done) {
      setState(() => _hintMsg = 'Select a word below, then tap a blank — or drag!');
    }
  });
}
void _reset() {
  _initSentences();
  setState(() {
    _filled.clear();
    _correct.clear();
    _wrongKey = null;
    _sparkleKey = null;
    _selectedChip = null;
    _dragTargetKey = null;
    _score = 0;
    _done = false;
    _hintMsg = 'Select a word below, then tap a blank — or drag!';
    _bank = List.from(_allWords)..shuffle(math.Random());
  });
}
  // ==========================================================================
  //  BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final lessonNumber = widget.lesson['number'] as int;
    final lessonTitle  = widget.lesson['title']  as String;

    return Scaffold(
      backgroundColor: _WPColors.tealBg,
      body: SafeArea(
        child: Stack(
          children: [
            // ── teal radial bg ──
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -1.2),
                    radius: 0.9,
                    colors: [Color(0xFF7CC9BD), _WPColors.tealBg],
                  ),
                ),
              ),
            ),

            Column(
              children: [
                _buildHeader(lessonNumber, lessonTitle),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildPaper()),
                      _buildSideRail(),
                    ],
                  ),
                ),
              ],
            ),

            // ── AI loading overlay ──
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
                      decoration: BoxDecoration(
                        color: _WPColors.paper,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 30)],
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const CircularProgressIndicator(color: _WPColors.purple),
                        const SizedBox(height: 16),
                        Text('Generating new sentences…',
                            style: GoogleFonts.nunito(
                                fontSize: 16, fontWeight: FontWeight.w700,
                                color: _WPColors.ink)),
                      ]),
                    ),
                  ),
                ),
              ),

            // ── confetti ──
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => _confettiCtrl.value > 0
                  ? IgnorePointer(child: _ConfettiOverlay(controller: _confettiCtrl))
                  : const SizedBox.shrink(),
            ),

            // ── win overlay ──
            if (_done) _buildWinOverlay(),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader(int lessonNumber, String lessonTitle) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _WPColors.headerBg,
        boxShadow: [BoxShadow(color: Color(0x2E000000), offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          // brand
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_WPColors.sun, _WPColors.coral],
              ),
              boxShadow: const [BoxShadow(color: _WPColors.coralDeep, offset: Offset(0, 3))],
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('name of web',
                  style: GoogleFonts.montserrat(
                      fontSize: 20, fontWeight: FontWeight.w900,
                      color: _WPColors.sun, letterSpacing: 0.5, height: 1)),
              const SizedBox(height: 3),
              Text('DIGITAL LITERACY',
                  style: GoogleFonts.nunito(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: const Color(0xFFFFE9B5), letterSpacing: 2)),
            ],
          ),
          const Spacer(),
          // lesson pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _WPColors.sun,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('#$lessonNumber',
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        color: _WPColors.ink, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Text(lessonTitle.toUpperCase(),
                  style: GoogleFonts.nunito(
                      fontSize: 13, color: const Color(0xFFFFE9B5),
                      letterSpacing: 1, fontWeight: FontWeight.w700)),
            ]),
          ),
          const Spacer(),
          // score pill
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, color: _WPColors.sun, size: 26),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('FILLED', style: GoogleFonts.nunito(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: const Color(0xFFFFE9B5), letterSpacing: 1.5)),
                  Text('$_score / $_total',
                      style: GoogleFonts.nunito(
                          fontSize: 18, color: _WPColors.cream, height: 1,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ]),
          ),
          const SizedBox(width: 14),
          // back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _WPColors.coral,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: _WPColors.coralDeep, offset: Offset(0, 3))],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── PAPER ──
  Widget _buildPaper() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: Container(
          color: _WPColors.paper,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _RuledLinesPainter())),
              const Positioned(
                left: 0, right: 0, bottom: 0, height: 140,
                child: IgnorePointer(child: _MeadowScene()),
              ),
              Column(
                children: [
                  Expanded(child: _buildSentences()),
                  _buildBankStrip(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildSentences() {
  return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(48, 16, 48, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _sentences
          .asMap()
          .entries
          .map((e) => _buildSentenceRow(e.key, e.value))
          .toList(),
    ),
  );
}

 Widget _buildSentenceRow(int si, _Sentence sentence) {
  final children = <Widget>[];
  for (final part in sentence.parts) {
    if (!part.isBlank) {
      final words = part.text!.split(' ');
      for (var i = 0; i < words.length; i++) {
        final w = words[i];
        if (w.isEmpty) continue;
        children.add(Text(
          i == words.length - 1 ? w : '$w ',
          style: GoogleFonts.nunito(
            fontSize: 19, fontWeight: FontWeight.w600,
            color: _WPColors.ink, height: 1.55,
          ),
        ));
      }
    } else {
      final blank = part.blank!;
      children.add(_PondBlank(
        blankId: blank.id,
        word: _filled[blank.id],
        isCorrect: _correct.contains(blank.id),
        isWrong: _wrongKey == blank.id,
        isSparkle: _sparkleKey == blank.id,
        isTarget: _dragTargetKey == blank.id,
        isSelectedTarget: _selectedChip != null && _filled[blank.id] == null,
        onTap: () {
          if (_correct.contains(blank.id)) return;
          if (_selectedChip != null) {
            _tryPlace(blank.id, _selectedChip!);
          }
        },
        onAccept: (word) {
          _tryPlace(blank.id, word);
          setState(() => _dragTargetKey = null);
        },
        onWillAccept: (word) {
          setState(() => _dragTargetKey = blank.id);
          return word != null && !_correct.contains(blank.id);
        },
        onLeave: (_) {
          if (_dragTargetKey == blank.id) setState(() => _dragTargetKey = null);
        },
      ));
    }
  }
  // ── REPLACE ONLY THIS PART ──
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 17),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 10,
          children: children,
        ),
      ),
  
    ],
  );
}

  // ── BANK STRIP ──
  Widget _buildBankStrip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 28, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x599BD96B)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // mascot + speech
          SizedBox(
            width: 250,
            child: Row(children: [
              _MascotChick(controller: _bounceCtrl, cheer: _done),
              const SizedBox(width: 10),
              Expanded(child: _SpeechBubble(text: _hintMsg)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Text('WORD BANK',
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800, fontSize: 11,
                            color: _WPColors.inkSoft, letterSpacing: 2)),
                    const Spacer(),
                    RichText(text: TextSpan(
                      style: GoogleFonts.nunito(fontSize: 14, color: _WPColors.ink),
                      children: [
                        TextSpan(text: '${_correct.length}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, color: _WPColors.mintDeep)),
                        TextSpan(text: ' / $_total filled'),
                      ],
                    )),
                  ]),
                ),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final w in _bank)
                      _WordChip(
                        word: w,
                        selected: _selectedChip == w,
                        onTap: () => setState(() {
                          _selectedChip = _selectedChip == w ? null : w;
                        }),
                      ),
                    if (_bank.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('— all placed —',
                            style: GoogleFonts.nunito(
                                fontSize: 16, color: _WPColors.inkSoft)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SIDE RAIL ──
  Widget _buildSideRail() {
    return Container(
      width: 80,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_WPColors.tealBg, _WPColors.tealBg2],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(children: [
        _RailButton(icon: Icons.arrow_back_ios_rounded,
            onTap: () => Navigator.of(context).pop()),
        const SizedBox(height: 14),
        _RailButton(icon: Icons.refresh_rounded, onTap: _isLoading ? null : _reset),
        const SizedBox(height: 14),
        _RailButton(
          icon: Icons.auto_awesome_rounded,
          onTap: _isLoading ? null : _loadAiSentences,
          color: _WPColors.sun,
        ),
        const SizedBox(height: 14),
        _RailButton(icon: Icons.lightbulb_rounded, onTap: _isLoading ? null : _giveHint),
        const Spacer(),
        _NextButton(
          pulsing: _done,
         onTap: _done ? () => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => DigitalWordSearchPage(lesson: widget.lesson, onChainFinished: widget.onChainFinished),
  ),
) : null,
        ),
      ]),
    );
  }

  // ── WIN OVERLAY ──
  Widget _buildWinOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xC72B2342),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
            decoration: BoxDecoration(
              color: _WPColors.paper,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 60, offset: Offset(0, 20))
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('⭐⭐⭐', style: TextStyle(fontSize: 48, letterSpacing: 6)),
              const SizedBox(height: 12),
              Text('Review Complete!',
                  style: GoogleFonts.nunito(
                      fontSize: 36, fontWeight: FontWeight.w800, color: _WPColors.ink)),
              const SizedBox(height: 8),
              Text('You filled in all $_total blanks correctly.',
                  style: GoogleFonts.nunito(fontSize: 18, color: _WPColors.inkSoft)),
              const SizedBox(height: 22),
              GestureDetector(
onTap: () {
  Navigator.of(context).pop(); // close dialog
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DigitalWordSearchPage(lesson: widget.lesson, onChainFinished: widget.onChainFinished),
    ),
  );
},                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: _WPColors.sun,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: _WPColors.sunDeep, offset: Offset(0, 5))],
                  ),
                  child: Text('Continue →',
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700, fontSize: 20, color: _WPColors.ink)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
//  POND BLANK
// ===========================================================================
class _PondBlank extends StatefulWidget {
  final String blankId;
  final String? word;
  final bool isCorrect, isWrong, isSparkle, isTarget, isSelectedTarget;
  final VoidCallback onTap;
  final void Function(String) onAccept;
  final bool Function(String?) onWillAccept;
  final void Function(String?) onLeave;

  const _PondBlank({
    required this.blankId, required this.word,
    required this.isCorrect, required this.isWrong,
    required this.isSparkle, required this.isTarget,
    required this.isSelectedTarget, required this.onTap,
    required this.onAccept, required this.onWillAccept, required this.onLeave,
  });

  @override
  State<_PondBlank> createState() => _PondBlankState();
}

class _PondBlankState extends State<_PondBlank>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
  }

  @override
  void didUpdateWidget(covariant _PondBlank old) {
    super.didUpdateWidget(old);
    if (widget.isWrong && !old.isWrong) _shake.forward(from: 0);
  }

  @override
  void dispose() { _shake.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    BoxDecoration deco;
    Color textColor;

    if (widget.isCorrect) {
      deco = BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_WPColors.mintLight, _WPColors.mint],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          const BoxShadow(color: _WPColors.mintDeep, offset: Offset(0, 4)),
          BoxShadow(color: _WPColors.mintDeep.withOpacity(0.30), blurRadius: 0, spreadRadius: 3),
        ],
      );
      textColor = _WPColors.ink;
    } else if (widget.isWrong) {
      deco = BoxDecoration(
        color: _WPColors.coral,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          const BoxShadow(color: _WPColors.coralDeep, offset: Offset(0, 4)),
          BoxShadow(color: _WPColors.coral.withOpacity(0.5), blurRadius: 0, spreadRadius: 4),
        ],
      );
      textColor = Colors.white;
    } else if (widget.word == null) {
      deco = BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0, 0.2), radius: 0.9,
          colors: [_WPColors.skyShadow, _WPColors.skyDark],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          if (widget.isTarget)
            const BoxShadow(color: _WPColors.coral, blurRadius: 0, spreadRadius: 4)
          else if (widget.isSelectedTarget)
            const BoxShadow(color: _WPColors.sun, blurRadius: 0, spreadRadius: 3),
          const BoxShadow(color: Color(0x33000000), offset: Offset(0, 4), blurRadius: 6),
        ],
      );
      textColor = Colors.transparent;
    } else {
      deco = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 3), blurRadius: 8)],
      );
      textColor = _WPColors.ink;
    }

    final inner = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
constraints: BoxConstraints(
  minWidth: 80,
  maxWidth: 200,
  minHeight: 34,
),      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: deco,
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Text(widget.word ?? ' ',
              style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 15,
                  fontWeight: FontWeight.w600, color: textColor)),
          if (widget.isCorrect)
            Positioned(
              top: -10, right: -8,
              child: Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(
                    color: _WPColors.mintDeep, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ),
          if (widget.isSparkle) const _SparkleBurst(),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedBuilder(
        animation: _shake,
        builder: (_, child) {
          final dx = math.sin(_shake.value * math.pi * 4) * (1 - _shake.value) * 8;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: DragTarget<String>(
          onWillAccept: widget.onWillAccept,
          onAccept: widget.onAccept,
          onLeave: widget.onLeave,
          builder: (_, __, ___) => GestureDetector(onTap: widget.onTap, child: inner),
        ),
      ),
    );
  }
}

// ===========================================================================
//  WORD CHIP
// ===========================================================================
class _WordChip extends StatelessWidget {
  final String word;
  final bool selected;
  final VoidCallback onTap;
  const _WordChip({required this.word, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? _WPColors.sun : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            width: 2, color: selected ? _WPColors.sunDeep : _WPColors.skyDark),
        boxShadow: [
          BoxShadow(
              color: selected ? _WPColors.sunDeep : _WPColors.skyDark,
              offset: const Offset(0, 3)),
        ],
      ),
      transform: selected
          ? (Matrix4.identity()..translate(0.0, -3.0)..scale(1.05))
          : Matrix4.identity(),
      child: Text(word,
          style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 16,
              fontWeight: FontWeight.w600, color: _WPColors.ink)),
    );

    return Draggable<String>(
      data: word,
      feedback: Material(color: Colors.transparent,
          child: Transform.scale(scale: 1.08, child: body)),
      childWhenDragging: Opacity(opacity: 0.35, child: body),
      child: GestureDetector(onTap: onTap, child: body),
    );
  }
}

// ===========================================================================
//  SPARKLE BURST
// ===========================================================================
class _SparkleBurst extends StatefulWidget {
  const _SparkleBurst();
  @override
  State<_SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends State<_SparkleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return SizedBox(width: 80, height: 60,
          child: Stack(alignment: Alignment.center, clipBehavior: Clip.none,
            children: List.generate(8, (i) {
              final angle = (i / 8) * math.pi * 2;
              final dist  = 30 * Curves.easeOut.transform(t);
              return Transform.translate(
                offset: Offset(math.cos(angle)*dist, math.sin(angle)*dist),
                child: Opacity(opacity: (1-t).clamp(0.0,1.0),
                  child: Container(width:8, height:8,
                      decoration: const BoxDecoration(color: _WPColors.sun, shape: BoxShape.circle))),
              );
            }),
          ),
        );
      },
    );
  }
}

// ===========================================================================
//  MASCOT CHICK
// ===========================================================================
class _MascotChick extends StatelessWidget {
  final AnimationController controller;
  final bool cheer;
  const _MascotChick({required this.controller, required this.cheer});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Transform.translate(
          offset: Offset(0, math.sin(t * math.pi) * -14),
          child: Transform.rotate(
            angle: math.sin(t * math.pi * 2) * 0.12,
            child: SizedBox(width: 56, height: 56,
                child: CustomPaint(painter: _ChickPainter(cheer: cheer))),
          ),
        );
      },
    );
  }
}

class _ChickPainter extends CustomPainter {
  final bool cheer;
  _ChickPainter({required this.cheer});
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 80;
    void ellipse(double cx, double cy, double rx, double ry, Color c) {
      canvas.drawOval(Rect.fromCenter(
          center: Offset(cx*s, cy*s), width: rx*2*s, height: ry*2*s),
          Paint()..color = c);
    }
    void circle(double cx, double cy, double r, Color c) {
      canvas.drawCircle(Offset(cx*s, cy*s), r*s, Paint()..color = c);
    }
    ellipse(30, 72, 6, 3, _WPColors.sunDeep);
    ellipse(50, 72, 6, 3, _WPColors.sunDeep);
    ellipse(40, 48, 26, 24, _WPColors.sun);
    ellipse(40, 52, 16, 14, _WPColors.sunLight);
    ellipse(18, 48, 6, 10, _WPColors.sunDeep);
    ellipse(62, 48, 6, 10, _WPColors.sunDeep);
    circle(40, 18, 4, _WPColors.sunDeep);
    if (cheer) {
      final p = Paint()
        ..color = _WPColors.ink ..strokeWidth = 3*s
        ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke;
      canvas.drawPath(Path()..moveTo(27*s,30*s)..quadraticBezierTo(31*s,24*s,36*s,30*s), p);
      canvas.drawPath(Path()..moveTo(44*s,30*s)..quadraticBezierTo(48*s,24*s,53*s,30*s), p);
    } else {
      circle(32,30,5,Colors.white); circle(48,30,5,Colors.white);
      circle(33,31,2.4,_WPColors.ink); circle(49,31,2.4,_WPColors.ink);
    }
    final beak = Path()
      ..moveTo(36*s,38*s)..lineTo(44*s,38*s)..lineTo(40*s,44*s)..close();
    canvas.drawPath(beak, Paint()..color = _WPColors.coral);
    canvas.drawCircle(Offset(24*s,42*s), 3*s, Paint()..color = _WPColors.coral.withOpacity(0.55));
    canvas.drawCircle(Offset(56*s,42*s), 3*s, Paint()..color = _WPColors.coral.withOpacity(0.55));
  }
  @override
  bool shouldRepaint(_ChickPainter o) => o.cheer != cheer;
}

// ===========================================================================
//  SPEECH BUBBLE
// ===========================================================================
class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpeechArrowPainter(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14,7,12,7),
        decoration: BoxDecoration(
          color: _WPColors.cream2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _WPColors.sunDeep, width: 2.5),
        ),
        child: Text(text,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 13,
                fontWeight: FontWeight.w500, color: _WPColors.ink, height: 1.25)),
      ),
    );
  }
}

class _SpeechArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
        Path()..moveTo(-2, size.height/2-9)..lineTo(-14, size.height/2)..lineTo(-2, size.height/2+9)..close(),
        Paint()..color = _WPColors.sunDeep);
    canvas.drawPath(
        Path()..moveTo(0, size.height/2-7)..lineTo(-10, size.height/2)..lineTo(0, size.height/2+7)..close(),
        Paint()..color = _WPColors.cream2);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

// ===========================================================================
//  RAIL BUTTON / NEXT BUTTON
// ===========================================================================
class _RailButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  const _RailButton({required this.icon, this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    final bg = color ?? _WPColors.purple;
    return Opacity(
      opacity: onTap != null ? 1 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.6), offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _NextButton extends StatefulWidget {
  final bool pulsing;
  final VoidCallback? onTap;
  const _NextButton({required this.pulsing, required this.onTap});
  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final scale = widget.pulsing ? 1 + (_c.value * 0.08) : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: widget.onTap != null ? _WPColors.sun : Colors.grey.withOpacity(0.4),
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: _WPColors.sunDeep, offset: Offset(0, 5))],
          ),
          child: Icon(Icons.chevron_right_rounded, size: 36,
              color: widget.onTap != null ? _WPColors.ink : Colors.white38),
        ),
      ),
    );
  }
}

// ===========================================================================
//  BACKGROUND PAINTERS
// ===========================================================================
class _RuledLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _WPColors.skyDeep.withOpacity(0.18)
      ..strokeWidth = 1;
    const spacing = 52.0;
    for (var y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
      canvas.drawLine(Offset(0, y+3), Offset(size.width, y+3), p);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class _MeadowScene extends StatelessWidget {
  const _MeadowScene();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _MeadowPainter(), size: Size.infinite);
}

class _MeadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawOval(Rect.fromCenter(center: Offset(w*0.15, h+30), width:600, height:180),
        Paint()..color = _WPColors.grass.withOpacity(0.9));
    canvas.drawOval(Rect.fromCenter(center: Offset(w*0.75, h+40), width:700, height:200),
        Paint()..color = const Color(0xCC7BC34A));
    canvas.drawOval(Rect.fromCenter(center: Offset(w*0.5, h+50), width:1000, height:160),
        Paint()..color = _WPColors.grass);
    canvas.drawCircle(Offset(w-80, 30), 32, Paint()..color = _WPColors.sun.withOpacity(0.85));
    canvas.drawCircle(Offset(w-80, 30), 22, Paint()..color = _WPColors.sunLight);
    final cloud = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawCircle(const Offset(160,38),18,cloud);
    canvas.drawCircle(const Offset(190,32),22,cloud);
    canvas.drawCircle(const Offset(220,40),18,cloud);
    canvas.drawOval(Rect.fromCenter(center: const Offset(190,48), width:84, height:28), cloud);
    final fc = [_WPColors.coral, _WPColors.sun, Colors.white];
    final fp = [const Offset(50,100), const Offset(140,110), const Offset(240,95),
                 const Offset(360,108), const Offset(460,100), const Offset(580,110),
                 const Offset(700,95), const Offset(820,108), const Offset(950,100)];
    for (var i = 0; i < fp.length; i++) {
      if (fp[i].dx > w) continue;
      canvas.drawCircle(fp[i], 4, Paint()..color = fc[i % 3]);
      canvas.drawCircle(fp[i], 1.5, Paint()..color = _WPColors.sunDeep);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

// ===========================================================================
//  CONFETTI
// ===========================================================================
class _ConfettiOverlay extends StatefulWidget {
  final AnimationController controller;
  const _ConfettiOverlay({required this.controller});
  @override State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay> {
  final _rand = math.Random();
  late final List<_Piece> _pieces;
  @override
  void initState() {
    super.initState();
    const colors = [_WPColors.sun, _WPColors.coral, _WPColors.mint,
                    _WPColors.sky, _WPColors.grass, _WPColors.purple];
    _pieces = List.generate(80, (_) => _Piece(
      x: _rand.nextDouble(), delay: _rand.nextDouble()*0.3,
      dur: 0.6+_rand.nextDouble()*0.45,
      color: colors[_rand.nextInt(colors.length)],
      rotSpeed: 2+_rand.nextDouble()*4,
    ));
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) {
        final t = widget.controller.value;
        return Stack(children: _pieces.map((p) {
          final lt = ((t-p.delay)/p.dur).clamp(0.0,1.0);
          return Positioned(
            left: p.x * MediaQuery.of(context).size.width,
            top: -30 + lt*(MediaQuery.of(context).size.height+60),
            child: Opacity(opacity: 1-0.6*lt,
              child: Transform.rotate(angle: lt*p.rotSpeed*math.pi,
                child: Container(width:10,height:14,
                    decoration: BoxDecoration(color:p.color, borderRadius:BorderRadius.circular(3))))),
          );
        }).toList());
      },
    );
  }
}

class _Piece {
  final double x, delay, dur, rotSpeed;
  final Color color;
  _Piece({required this.x, required this.delay, required this.dur,
          required this.color, required this.rotSpeed});
}
