import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data_review_page.dart';
import '../services/api_service.dart';

// ── DATA MODEL ──
class _Blank {
  final String id;
  final String answer;
  const _Blank(this.id, this.answer);
}

// ── DEFAULT CONTENT ──
final List<List<dynamic>> _kSentences = [
  ['Sue wanted to put her ', const _Blank('b1', 'numerical'), ' data in ', const _Blank('b2', 'ascending'), ' order, so she started the list with the least value number and ended with the ', const _Blank('b3', 'greatest'), ' value.'],
  ['Calvin likes creating ', const _Blank('b4', 'picture graphs'), ' because he gets to draw cool images of the data he collected.'],
  ['Bar Charts use the ', const _Blank('b5', 'height'), ' of the columns to display quantity.'],
  ['A ', const _Blank('b6', 'table'), ' is a good way to organize data without graphing it.'],
  [const _Blank('b7', 'Hash'), ' marks are a simple way to count how many times a value occurs.'],
];

const List<String> _kWordBank = [
  'table', 'descending', 'numerical', 'greatest',
  'Question', 'line plots', 'data', 'height',
  'width', 'picture graphs', 'Hash', 'ascending',
];

// ── PAGE ──
class DataFillBlankPage extends StatefulWidget {
  final Map<String, dynamic> lesson;
  const DataFillBlankPage({super.key, required this.lesson});

  @override
  State<DataFillBlankPage> createState() => _DataFillBlankPageState();
}

class _DataFillBlankPageState extends State<DataFillBlankPage> {
  List<List<dynamic>> _sentences = _kSentences;
  List<String> _wordBank = List.of(_kWordBank);

  final Map<String, String> _filled = {};
  String? _selectedWord;
  final Set<String> _wrongFlash = {};
  bool _done = false;
  bool _isLoading = false;

  int get _totalBlanks {
    int n = 0;
    for (final s in _sentences) {
      for (final p in s) { if (p is _Blank) n++; }
    }
    return n;
  }

  void _tapWord(String word) {
    setState(() => _selectedWord = _selectedWord == word ? null : word);
  }

  void _tapBlank(_Blank blank) {
    if (_selectedWord == null) return;
    final word = _selectedWord!;
    if (word == blank.answer) {
      _filled[blank.id] = word;
      setState(() => _selectedWord = null);
      if (_filled.length == _totalBlanks) {
        final lessonNumber = widget.lesson['number'] as int;
        ApiService.saveLevelResult(
          gameId: 'data-everywhere',
          level: lessonNumber,
          completed: true,
          score: 3,
        );
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() => _done = true);
            _showCompletedDialog();
          }
        });
      }
    } else {
      setState(() {
        _wrongFlash.add(blank.id);
        _selectedWord = null;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _wrongFlash.remove(blank.id));
      });
    }
  }

  void _unfillBlank(_Blank blank) {
    setState(() => _filled.remove(blank.id));
  }

  Future<void> _loadAiContent() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _sentences = _kSentences;
      _wordBank = List.of(_kWordBank);
      _filled.clear();
      _selectedWord = null;
      _wrongFlash.clear();
      _done = false;
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('AI content coming soon — using defaults.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  void _showCompletedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎉 Great Job!',
            style: TextStyle(fontFamily: 'Chennai', fontSize: 24)),
        content: const Text('You filled in all the blanks correctly!',
            style: TextStyle(fontFamily: 'Chennai', fontSize: 16)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => DataReviewPage(lesson: widget.lesson),
              ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623)),
            child: const Text('CONTINUE',
                style: TextStyle(
                    fontFamily: 'Chennai',
                    color: Colors.white,
                    fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonNumber = widget.lesson['number'] as int;
    final lessonTitle = widget.lesson['title'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFF7B9FD4),
      body: Column(
        children: [
          // ── CODEMONKEY NAVBAR ──
          Container(
            color: const Color.fromARGB(255, 252, 183, 199),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/sprites/logocodey.png',
                        height: 40, fit: BoxFit.contain),
                    const SizedBox(width: 24),
                    Text(
                      'DATA EVERYWHERE: MINI COURSE: #$lessonNumber ${lessonTitle.toUpperCase()}',
                      style: GoogleFonts.montserrat(
                        color: Colors.white70,
                        fontSize: 13, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Image.asset('assets/images/sprites/avatar00.png',
                        width: 36, height: 36),
                    const SizedBox(width: 16),
                    Image.asset('assets/images/sprites/btn_menu.png',
                        width: 24, height: 24),
                  ],
                ),
              ],
            ),
          ),
          _buildTopBar(lessonNumber, lessonTitle),
          Expanded(
            child: Row(
              children: [
                _buildSideButton(
                  icon: Icons.arrow_back_ios,
                  label: 'PREVIOUS',
                  onTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 1170,
                      height: 700,
                      child: _buildGameArea(),
                    ),
                  ),
                ),
                _buildSideButton(
                  icon: Icons.arrow_forward_ios,
                  label: 'NEXT',
                  onTap: _done
                      ? () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                DataReviewPage(lesson: widget.lesson),
                          ))
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TOP BAR ──
  Widget _buildTopBar(int lessonNumber, String lessonTitle) {
    return Container(
      color: const Color(0xFFADE8F4),
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context)
                .popUntil((route) => route.isFirst),
            child: Container(
              width: 52, height: 52,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF5B8FD4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
                  Text('BACK TO\nCOURSE',
                      style: GoogleFonts.nunito(
                        color: Colors.white, fontSize: 7,
                        fontWeight: FontWeight.w800, height: 1.1,
                      ),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('#$lessonNumber',
              style: const TextStyle(
                  fontFamily: 'Chennai',
                  color: Color(0xFF333333), fontSize: 22)),
          const SizedBox(width: 8),
          Text(lessonTitle,
              style: const TextStyle(
                  fontFamily: 'Chennai',
                  color: Color(0xFF333333), fontSize: 24)),
          const Spacer(),
          GestureDetector(
            onTap: _isLoading ? null : _loadAiContent,
            child: Opacity(
              opacity: _isLoading ? 0.4 : 1.0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  Text('AI',
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildTopBox(
            icon: Icons.menu_book,
            iconColor: const Color(0xFF5B8FD4),
            label: 'LEARN',
            value: '17/17',
            bgColor: const Color(0xFF5B8FD4).withValues(alpha: 0.15),
          ),
          const SizedBox(width: 8),
          _buildFillBox(),
          const SizedBox(width: 8),
          _buildTopBox(
            icon: Icons.chat_bubble_outline,
            iconColor: const Color(0xFF888888),
            label: 'REVIEW',
            value: '0/5',
            bgColor: Colors.grey.withValues(alpha: 0.15),
            locked: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color bgColor,
    bool locked = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 6),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF555555))),
            Row(children: [
              if (locked)
                const Icon(Icons.lock, size: 10, color: Color(0xFF888888)),
              Text(value,
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF333333))),
            ]),
          ],
        ),
      ]),
    );
  }

  Widget _buildFillBox() {
    final total = _totalBlanks;
    final filled = _filled.length;
    final displayCount = math.min(total, 7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.edit_rounded, color: Color(0xFF4CAF50), size: 18),
        const SizedBox(width: 6),
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FILL',
                style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF555555))),
            Row(
              children: List.generate(displayCount, (i) {
                return Container(
                  margin: const EdgeInsets.only(right: 3),
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: i < filled
                        ? const Color(0xFF4CAF50)
                        : i == filled
                            ? Colors.white
                            : Colors.grey.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: i <= filled
                            ? const Color(0xFF4CAF50)
                            : Colors.grey,
                        width: 1),
                  ),
                  child: i == filled
                      ? Center(
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333))))
                      : null,
                );
              }),
            ),
          ],
        ),
      ]),
    );
  }

  // ── GAME AREA ──
  Widget _buildGameArea() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── BACKGROUND + CONTENT ──
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/digitalbackground.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(48, 24, 48, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < _sentences.length; i++) ...[
                        _buildSentence(_sentences[i]),
                        if (i < _sentences.length - 1)
                          Divider(
                              color: Colors.white.withValues(alpha: 0.4),
                              height: 24),
                      ],
                    ],
                  ),
                ),
              ),
              _buildWordBank(),
            ],
          ),
        ),
        // ── AI LOADING OVERLAY ──
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(
                      color: Color(0xFFF5A623)),
                  const SizedBox(height: 14),
                  Text('Generating new content…',
                      style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSentence(List<dynamic> parts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 12,
        children: parts.map((part) {
          if (part is String) {
            return Text(part,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                          color: Colors.black45,
                          offset: Offset(0, 1),
                          blurRadius: 2)
                    ]));
          } else if (part is _Blank) {
            return _buildBlankWidget(part);
          }
          return const SizedBox.shrink();
        }).toList(),
      ),
    );
  }

  Widget _buildBlankWidget(_Blank blank) {
    final filled = _filled[blank.id];
    final isWrong = _wrongFlash.contains(blank.id);
    final hasWord = filled != null;
    final canReceive = !hasWord && _selectedWord != null;

    final Color bg = isWrong
        ? const Color(0xFFEF9A9A)
        : hasWord
            ? const Color(0xFFB8EEB8)
            : const Color(0xFFEAE8F5);
    final Color border = isWrong
        ? const Color(0xFFE53935)
        : hasWord
            ? const Color(0xFF4CAF50)
            : canReceive
                ? const Color(0xFFF5A623)
                : const Color(0xFF777777);

    return GestureDetector(
      onTap: hasWord ? () => _unfillBlank(blank) : () => _tapBlank(blank),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minWidth: 110),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border, width: canReceive ? 3 : 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Center(
          child: hasWord
              ? Text(filled,
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF333333)))
              : const SizedBox(height: 20, width: 70),
        ),
      ),
    );
  }

  // ── WORD BANK ──
  Widget _buildWordBank() {
    final usedWords = _filled.values.toSet();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border(
            top: BorderSide(
                color: Colors.white.withValues(alpha: 0.3), width: 1.5)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: _wordBank.map((word) {
          final isUsed = usedWords.contains(word);
          final isSelected = _selectedWord == word;
          return GestureDetector(
            onTap: isUsed ? null : () => _tapWord(word),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isUsed
                    ? Colors.white.withValues(alpha: 0.25)
                    : isSelected
                        ? const Color(0xFFF5A623)
                        : const Color(0xFFEAE8F5),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFE0A300)
                      : const Color(0xFF777777),
                  width: isSelected ? 2.5 : 2,
                ),
                boxShadow: isUsed
                    ? []
                    : [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
              ),
              child: Text(word,
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isUsed
                          ? Colors.white.withValues(alpha: 0.5)
                          : isSelected
                              ? const Color(0xFF1A1A2E)
                              : const Color(0xFF333333))),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── SIDE BUTTON ──
  Widget _buildSideButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final bool enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: double.infinity,
        color: const Color.fromARGB(255, 123, 159, 212),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFFF5A623)
                    : Colors.grey.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.nunito(
                    color: enabled ? Colors.white : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
