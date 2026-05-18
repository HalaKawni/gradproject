import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class DataReviewPage extends StatefulWidget {
  final Map<String, dynamic> lesson;
  const DataReviewPage({super.key, required this.lesson});

  @override
  State<DataReviewPage> createState() => _DataReviewPageState();
}

class _DataReviewPageState extends State<DataReviewPage>
    with TickerProviderStateMixin {

  late List<_Sentence> _sentences;

  final List<String> _allWords = [
    'data', 'survey', 'tally', 'qualitative',
    'bar graph', 'pie chart', 'line graph', 'frequency',
    'quantitative', 'observation',
  ];

  late List<String> _bank;
  final Map<String, String> _filled = {};
  final Set<String> _correct = {};
  String? _wrongKey;
  String? _sparkleKey;
  String? _selectedChip;
  String? _dragTargetKey;

  int _score = 0;
  bool _done = false;
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

  void _initSentences() {
    _sentences = [
      _Sentence([
        _SentencePart.text('Information collected for analysis, like numbers and measurements, is called '),
        _SentencePart.blank(_Blank(id: 'b1', answer: 'data')),
        _SentencePart.text('.'),
      ]),
      _Sentence([
        _SentencePart.text('When we ask a group of people questions to collect information, we call it a '),
        _SentencePart.blank(_Blank(id: 'b2', answer: 'survey')),
        _SentencePart.text('.'),
      ]),
      _Sentence([
        _SentencePart.text('A '),
        _SentencePart.blank(_Blank(id: 'b3', answer: 'bar graph')),
        _SentencePart.text(' uses rectangular bars to compare different categories of data.'),
      ]),
      _Sentence([
        _SentencePart.text('A '),
        _SentencePart.blank(_Blank(id: 'b4', answer: 'line graph')),
        _SentencePart.text(' connects points to show how data changes over time.'),
      ]),
      _Sentence([
        _SentencePart.text('A '),
        _SentencePart.blank(_Blank(id: 'b5', answer: 'pie chart')),
        _SentencePart.text(' is a circle divided into slices that show parts of a whole.'),
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
          final lessonNumber = widget.lesson['number'] as int;
          ApiService.saveFillBlanksScore(
            gameId: 'data-everywhere',
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

  @override
  Widget build(BuildContext context) {
    final lessonNumber = widget.lesson['number'] as int;
    final lessonTitle = widget.lesson['title'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFF7B9FD4),
      body: Column(
        children: [
          _buildNavbar(lessonNumber, lessonTitle),
          _buildTopBar(lessonNumber, lessonTitle),
          Expanded(
            child: Stack(
              children: [
                _buildBody(),
                if (_done) _buildConfetti(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavbar(int lessonNumber, String lessonTitle) {
    return Container(
      color: const Color(0xFF2D1B0A), height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(width: 38, height: 38,
                decoration: const BoxDecoration(color: Color(0xFF8B5E3C), shape: BoxShape.circle),
                child: const Icon(Icons.pets, color: Colors.white, size: 20)),
            const SizedBox(width: 10),
            Text('CODEMONKEY',
                style: GoogleFonts.montserrat(color: const Color(0xFFF5A623), fontSize: 18,
                    fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const SizedBox(width: 24),
            Text('DATA IS EVERYWHERE: MINI COURSE: #$lessonNumber ${lessonTitle.toUpperCase()}',
                style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
          Row(children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(color: const Color(0xFF4A7DBF), shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2)),
                child: const Icon(Icons.person, color: Colors.white, size: 20)),
            const SizedBox(width: 16),
            const Icon(Icons.menu, color: Colors.white, size: 24),
          ]),
        ],
      ),
    );
  }

  Widget _buildTopBar(int lessonNumber, String lessonTitle) {
    return Container(
      color: const Color(0xFFADE8F4), height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).popUntil(
                (route) => route.settings.name == 'data_course_hub' || route.isFirst),
            child: Container(
              width: 52, height: 52, padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFF5B8FD4), borderRadius: BorderRadius.circular(8)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
                Text('BACK TO\nCOURSE',
                    style: GoogleFonts.nunito(color: Colors.white, fontSize: 7,
                        fontWeight: FontWeight.w800, height: 1.1),
                    textAlign: TextAlign.center),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Text('#$lessonNumber',
              style: const TextStyle(fontFamily: 'Chennai', color: Color(0xFF333333), fontSize: 22)),
          const SizedBox(width: 8),
          Text(lessonTitle,
              style: const TextStyle(fontFamily: 'Chennai', color: Color(0xFF333333), fontSize: 24)),
          const Spacer(),
          _buildTopBox(icon: Icons.menu_book, iconColor: const Color(0xFF5B8FD4),
              label: 'LEARN', value: '10/10',
              bgColor: const Color(0xFF5B8FD4).withValues(alpha: 0.15)),
          const SizedBox(width: 8),
          _buildTopBox(icon: Icons.sports_esports, iconColor: const Color(0xFF4CAF50),
              label: 'PLAY', value: '4/4',
              bgColor: const Color(0xFF4CAF50).withValues(alpha: 0.15)),
          const SizedBox(width: 8),
          _buildTopBox(icon: Icons.chat_bubble_outline, iconColor: const Color(0xFF4A90C4),
              label: 'REVIEW', value: '$_score/$_total',
              bgColor: const Color(0xFF4A90C4).withValues(alpha: 0.15)),
        ],
      ),
    );
  }

  Widget _buildTopBox({required IconData icon, required Color iconColor,
      required String label, required String value, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4))),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 6),
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(label, style: GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w800,
              color: const Color(0xFF555555))),
          Text(value, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800,
              color: const Color(0xFF333333))),
        ]),
      ]),
    );
  }

  Widget _buildBody() {
    return Row(
      children: [
        _buildSideButton(icon: Icons.arrow_back_ios, label: 'PREVIOUS',
            onTap: () => Navigator.of(context).pop()),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildSentences()),
                _buildWordBank(),
              ],
            ),
          ),
        ),
        _buildSideButton(icon: Icons.arrow_forward_ios, label: 'FINISH',
            onTap: _done ? () => Navigator.of(context).popUntil(
                (route) => route.settings.name == 'data_course_hub' || route.isFirst) : null),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF4A90C4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('REVIEW', style: GoogleFonts.nunito(color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.w800, letterSpacing: 1)),
              Text('Fill in the Blanks', style: GoogleFonts.nunito(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(_hintMsg, key: ValueKey(_hintMsg),
                style: GoogleFonts.nunito(color: Colors.white70, fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20)),
            child: Text('$_score / $_total',
                style: GoogleFonts.nunito(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildSentences() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _sentences.map((sentence) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: sentence.parts.map((part) {
              if (!part.isBlank) {
                return Text(part.text!,
                    style: GoogleFonts.nunito(fontSize: 18, color: const Color(0xFF333333),
                        fontWeight: FontWeight.w600));
              }
              final blankId = part.blank!.id;
              final filled = _filled[blankId];
              final isCorrect = _correct.contains(blankId);
              final isWrong = _wrongKey == blankId;
              final isSparkling = _sparkleKey == blankId;

              return GestureDetector(
                onTap: () {
                  if (isCorrect) return;
                  if (_selectedChip != null) {
                    _tryPlace(blankId, _selectedChip!);
                  } else if (filled != null && !isCorrect) {
                    setState(() { _bank.add(filled); _filled.remove(blankId); });
                  }
                },
                child: DragTarget<String>(
                  onAcceptWithDetails: (details) => _tryPlace(blankId, details.data),
                  onWillAcceptWithDetails: (details) {
                    setState(() => _dragTargetKey = blankId);
                    return true;
                  },
                  onLeave: (_) => setState(() => _dragTargetKey = null),
                  builder: (context, candidateData, rejectedData) {
                    final isTarget = _dragTargetKey == blankId && candidateData.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      constraints: const BoxConstraints(minWidth: 120),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? const Color(0xFFD4F8E8)
                            : isWrong
                                ? const Color(0xFFFFE0E0)
                                : isTarget
                                    ? const Color(0xFFE3F2FD)
                                    : filled != null
                                        ? const Color(0xFFFFF9C4)
                                        : const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCorrect
                              ? const Color(0xFF4CAF50)
                              : isWrong
                                  ? const Color(0xFFE53935)
                                  : isTarget
                                      ? const Color(0xFF4A90C4)
                                      : filled != null
                                          ? const Color(0xFFFFCA28)
                                          : const Color(0xFFBBCCFF),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSparkling)
                            const Text('✨ ', style: TextStyle(fontSize: 16)),
                          Text(
                            filled ?? '___________',
                            style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: isCorrect
                                  ? const Color(0xFF2E7D32)
                                  : isWrong
                                      ? const Color(0xFFE53935)
                                      : filled != null
                                          ? const Color(0xFF333333)
                                          : const Color(0xFFAAAAAA),
                            ),
                          ),
                          if (isCorrect)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildWordBank() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WORD BANK', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800,
              color: const Color(0xFF888888), letterSpacing: 1)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _bank.map((word) {
              final isSelected = _selectedChip == word;
              return Draggable<String>(
                data: word,
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        color: const Color(0xFF4A90C4),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8, offset: const Offset(0, 4))]),
                    child: Text(word, style: GoogleFonts.nunito(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _chipWidget(word, false),
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedChip = isSelected ? null : word),
                  child: _chipWidget(word, isSelected),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _chipWidget(String word, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4A90C4) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isSelected ? const Color(0xFF4A90C4) : const Color(0xFFCCDDFF), width: 2),
        boxShadow: isSelected
            ? [const BoxShadow(color: Color(0xFF4A90C4), blurRadius: 6, offset: Offset(0, 3))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)],
      ),
      child: Text(word,
          style: GoogleFonts.nunito(
              color: isSelected ? Colors.white : const Color(0xFF333333),
              fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildSideButton({required IconData icon, required String label, required VoidCallback? onTap}) {
    final bool enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, height: double.infinity, color: const Color(0xFF7B7FD4),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFFF5A623) : Colors.grey.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.nunito(
              color: enabled ? Colors.white : Colors.white38,
              fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiCtrl,
      builder: (context, _) {
        final rng = math.Random(42);
        return CustomPaint(
          painter: _ConfettiPainter(progress: _confettiCtrl.value, rng: rng),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

// ── CONFETTI PAINTER ──
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final math.Random rng;
  _ConfettiPainter({required this.progress, required this.rng});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [Colors.red, Colors.blue, Colors.yellow, Colors.green, Colors.purple, Colors.orange];
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = -30 + progress * (size.height + 60) + rng.nextDouble() * 100 - 50;
      final color = colors[i % colors.length];
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 8, height: 14),
            const Radius.circular(2)),
        Paint()..color = color.withValues(alpha: (1 - progress).clamp(0, 1)),
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ── DATA MODELS ──
class _Blank {
  final String id;
  final String answer;
  _Blank({required this.id, required this.answer});
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
