part of 'classroom_page.dart';

// ── _BCard ────────────────────────────────────────────────────────────────────
class _BCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  const _BCard({required this.child, this.margin});

  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: .07), blurRadius: 18,
          offset: const Offset(0, 5))],
    ),
    child: child,
  );
}

// ── _StatChip (mobile compact tile) ──────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String emoji, value, label;
  final Color color, bg;
  const _StatChip({required this.emoji, required this.value, required this.label,
      required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 11),
    margin: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 3),
      Text(value, style: GoogleFonts.fredoka(fontSize: 20,
          fontWeight: FontWeight.w700, color: color)),
      Text(label, style: GoogleFonts.fredoka(fontSize: 10.5, color: _kMuted)),
    ]),
  ));
}

// ── _StatCard (desktop wide tile) ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String emoji, value, label;
  final Color color, bg;
  const _StatCard({required this.emoji, required this.value, required this.label,
      required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06),
          blurRadius: 14, offset: const Offset(0, 4))],
    ),
    child: Row(children: [
      Container(width: 50, height: 50,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 24))),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.fredoka(fontSize: 26,
            fontWeight: FontWeight.w700, color: color)),
        Text(label, style: GoogleFonts.fredoka(fontSize: 12.5, color: _kMuted)),
      ]),
    ]),
  ));
}

// ── _CodeyMascot ──────────────────────────────────────────────────────────────
class _CodeyMascot extends StatelessWidget {
  final double size;
  const _CodeyMascot({required this.size});

  @override
  Widget build(BuildContext context) {
    final s = size;
    return SizedBox(
      width: s,
      height: s * 1.18,
      child: Stack(alignment: Alignment.center, children: [
        // antenna stem
        Positioned(
          top: 0, left: s * 0.42,
          child: Column(children: [
            Container(
              width: s * 0.1, height: s * 0.2,
              decoration: BoxDecoration(
                color: const Color(0xFFBDB3FF),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              width: s * 0.22, height: s * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: _kGold,
                boxShadow: [BoxShadow(
                    color: _kGold.withValues(alpha: .7), blurRadius: 8)],
              ),
            ),
          ]),
        ),
        // face
        Positioned(
          bottom: 0,
          child: Container(
            width: s, height: s * 0.88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF27E0BE), _kMint],
              ),
              borderRadius: BorderRadius.circular(s * 0.28),
              boxShadow: [BoxShadow(
                  color: _kMint.withValues(alpha: .3), blurRadius: 14,
                  offset: const Offset(0, 5))],
            ),
            child: Stack(children: [
              // screen / eyes
              Positioned(
                top: s * 0.18, left: s * 0.1, right: s * 0.1,
                child: Container(
                  height: s * 0.36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2F3C),
                    borderRadius: BorderRadius.circular(s * 0.1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_eye(s), _eye(s)],
                  ),
                ),
              ),
              // mouth
              Positioned(
                bottom: s * 0.12, left: s * 0.3, right: s * 0.3,
                child: Container(
                  height: s * 0.13,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: const Color(0xFF0F2F3C), width: s * 0.04),
                      left:   BorderSide(color: const Color(0xFF0F2F3C), width: s * 0.04),
                      right:  BorderSide(color: const Color(0xFF0F2F3C), width: s * 0.04),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _eye(double s) => Container(
    width: s * 0.14, height: s * 0.2,
    decoration: BoxDecoration(
      color: const Color(0xFF7DF7E3),
      borderRadius: BorderRadius.circular(s * 0.1),
    ),
  );
}

// ── _ColoredAvatar ────────────────────────────────────────────────────────────
class _ColoredAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double? radius;
  const _ColoredAvatar({required this.name, required this.size, this.radius});

  static const _palettes = [
    [Color(0xFF7B68FF), Color(0xFF6C5CE7)],
    [Color(0xFF27E0BE), Color(0xFF10C8A8)],
    [Color(0xFFFF8A8A), Color(0xFFFF6B6B)],
    [Color(0xFFFFD06A), Color(0xFFFFB938)],
    [Color(0xFF6FC4FF), Color(0xFF38A8F5)],
  ];

  @override
  Widget build(BuildContext context) {
    final idx = name.isEmpty ? 0 : name.codeUnitAt(0) % _palettes.length;
    final c   = _palettes[idx];
    final r   = radius ?? size * 0.3;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [c[0], c[1]]),
        borderRadius: BorderRadius.circular(r),
      ),
      alignment: Alignment.center,
      child: Text(
        name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
        style: GoogleFonts.fredoka(fontSize: size * 0.4,
            fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

// ── _AnimatedProgressBar ──────────────────────────────────────────────────────
class _AnimatedProgressBar extends StatelessWidget {
  final int current, target;
  final bool done;
  const _AnimatedProgressBar({required this.current, required this.target,
      required this.done});

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: pct),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (_, value, w) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 14,
            decoration: BoxDecoration(color: const Color(0xFFEDEAF7),
                borderRadius: BorderRadius.circular(10)),
            child: FractionallySizedBox(
              widthFactor: value, alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: done
                        ? [const Color(0xFF10C8A8), const Color(0xFF27E0BE)]
                        : [const Color(0xFF7B68FF), const Color(0xFF10C8A8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(
                      color: _kViolet.withValues(alpha: .4), blurRadius: 10)],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text('$current / $target levels completed',
          style: GoogleFonts.fredoka(fontSize: 12.5, color: _kMuted)),
    ]);
  }
}

// ── _StreakRow ────────────────────────────────────────────────────────────────
class _StreakRow extends StatelessWidget {
  final dynamic member;
  const _StreakRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final name   = member['name']   as String? ?? 'Unknown';
    final streak = member['streak'] as int?    ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        _ColoredAvatar(name: name, size: 36, radius: 12),
        const SizedBox(width: 10),
        SizedBox(width: 82,
            child: Text(name,
                style: GoogleFonts.fredoka(fontSize: 13.5, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 6),
        Expanded(child: Text('🔥' * streak.clamp(0, 7),
            style: const TextStyle(fontSize: 15))),
        streak > 0
            ? Text('${streak}d', style: GoogleFonts.fredoka(fontSize: 12, color: _kMuted))
            : Text('—', style: GoogleFonts.fredoka(fontSize: 12,
                color: const Color(0xFFC2BFD6))),
      ]),
    );
  }
}

// ── _ChallengeRow ─────────────────────────────────────────────────────────────
class _ChallengeRow extends StatelessWidget {
  final dynamic challenge;
  const _ChallengeRow({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final status = challenge['status'] as String? ?? 'pending';
    final done   = status == 'completed';
    final game   = _gameLabels[challenge['gameId']] ?? challenge['gameId'] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: done ? _kMintSoft : _kGoldSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(done ? '✅' : '⚔️',
              style: const TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${challenge['challengerName']} vs ${challenge['challengedName']}',
              style: GoogleFonts.fredoka(fontSize: 13.5, fontWeight: FontWeight.w600)),
          Text(done
              ? '$game · Winner: ${challenge['winner'] ?? 'TBD'}'
              : '$game · Score to beat: ${challenge['challengerScore']}',
              style: GoogleFonts.fredoka(fontSize: 12, color: _kMuted)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: done ? _kMintSoft : _kGoldSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(done ? 'Done' : 'Pending',
              style: GoogleFonts.fredoka(fontSize: 11.5, fontWeight: FontWeight.w600,
                  color: done ? const Color(0xFF08967D) : const Color(0xFFD88A0E))),
        ),
      ]),
    );
  }
}

// ── _MemberCard ───────────────────────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final dynamic member;
  final List<String> badges;
  final VoidCallback onChallenge;
  const _MemberCard({required this.member, required this.badges,
      required this.onChallenge});

  static const _rankColors = {
    1: Color(0xFFFFB938), 2: Color(0xFFAEB7C9), 3: Color(0xFFCD7F32),
  };
  static const _medals = {1: '🥇', 2: '🥈', 3: '🥉'};

  @override
  Widget build(BuildContext context) {
    final rank   = member['rank']       as int?    ?? 0;
    final name   = member['name']       as String? ?? 'Unknown';
    final stars  = member['totalStars'] as int?    ?? 0;
    final score  = member['totalScore'] as int?    ?? 0;
    final streak = member['streak']     as int?    ?? 0;
    final rc     = _rankColors[rank] ?? const Color(0xFF9C98BE);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: rc),
            Expanded(child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Row(children: [
                SizedBox(width: 36, child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_medals[rank] ?? '🎓',
                      style: const TextStyle(fontSize: 19)),
                  Text('#$rank', style: GoogleFonts.fredoka(fontSize: 11.5,
                      fontWeight: FontWeight.w700, color: rc)),
                ])),
                const SizedBox(width: 8),
                _ColoredAvatar(name: name, size: 44, radius: 14),
                const SizedBox(width: 10),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, children: [
                  Row(children: [
                    Flexible(child: Text(name,
                        style: GoogleFonts.fredoka(fontSize: 14.5,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 5),
                    ...badges.map((b) =>
                        Text(b, style: const TextStyle(fontSize: 15))),
                  ]),
                  if (streak > 0)
                    Text('🔥 $streak day streak',
                        style: GoogleFonts.fredoka(fontSize: 12,
                            color: const Color(0xFFE59512))),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('⭐ $stars',
                      style: GoogleFonts.fredoka(fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text('$score pts',
                      style: GoogleFonts.fredoka(fontSize: 11.5, color: _kMuted)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onChallenge,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kCoralSoft, borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFCCCA)),
                      ),
                      child: Text('🎯 Challenge',
                          style: GoogleFonts.fredoka(fontSize: 11.5,
                              fontWeight: FontWeight.w600, color: _kCoral)),
                    ),
                  ),
                ]),
              ]),
            )),
          ],
        )),
      ),
    );
  }
}

// ── _PodiumColumn ─────────────────────────────────────────────────────────────
class _PodiumColumn extends StatelessWidget {
  final dynamic entry;
  final int rank;
  final double standHeight;
  final Color color;
  const _PodiumColumn({required this.entry, required this.rank,
      required this.standHeight, required this.color});

  @override
  Widget build(BuildContext context) {
    final name  = entry['name']       as String? ?? '?';
    final score = entry['totalScore'] as int?    ?? 0;
    final avSz  = rank == 1 ? 64.0 : 52.0;
    return Expanded(child: Column(
      mainAxisAlignment: MainAxisAlignment.end, children: [
      if (rank == 1)
        const Text('👑', style: TextStyle(fontSize: 20)),
      _ColoredAvatar(name: name, size: avSz, radius: avSz / 2),
      const SizedBox(height: 5),
      Text(name,
          style: GoogleFonts.fredoka(fontSize: 12.5, fontWeight: FontWeight.w600),
          maxLines: 1, overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center),
      Text('$score pts',
          style: GoogleFonts.fredoka(fontSize: 12, color: _kVioletD)),
      const SizedBox(height: 4),
      Container(
        width: double.infinity, height: standHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: .85), color],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14), topRight: Radius.circular(14)),
        ),
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(top: 8),
        child: Text('$rank',
            style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
    ]));
  }
}

// ── _DesktopSidebar ───────────────────────────────────────────────────────────
class _DesktopSidebar extends StatelessWidget {
  final VoidCallback onBack;
  final String? classroomCode;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onShare;
  const _DesktopSidebar({required this.onBack, required this.classroomCode, required this.selectedIndex,
      required this.onSelect, required this.onShare});

  static const _items = [
    (Icons.bar_chart_rounded,     'Overview'),
    (Icons.people_rounded,        'Members'),
    (Icons.emoji_events_rounded,  'Ranks'),
    (Icons.bolt_rounded,          'Activity'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF7B68FF), _kViolet, _kVioletD],
        ),
      ),
      child: SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // brand
          Row(children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const _CodeyMascot(size: 42),
            const SizedBox(width: 12),
            RichText(text: TextSpan(
              style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700),
              children: const [
                TextSpan(text: 'Cod', style: TextStyle(color: Colors.white)),
                TextSpan(text: 'ey',  style: TextStyle(color: Color(0xFF9FF3E2))),
              ],
            )),
          ]),
          const SizedBox(height: 22),
          // classroom box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MY CLASSROOM', style: GoogleFonts.fredoka(
                  fontSize: 10.5, color: Colors.white60, letterSpacing: .6)),
              const SizedBox(height: 4),
              Text('My Classroom', style: GoogleFonts.fredoka(
                  fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
              if (classroomCode != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🔑 ', style: TextStyle(fontSize: 12)),
                    Text(classroomCode!, style: GoogleFonts.fredoka(
                        fontSize: 13.5, fontWeight: FontWeight.w600,
                        letterSpacing: 2.5, color: Colors.white)),
                  ]),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 22),
          // nav items
          ...List.generate(_items.length, (i) => _NavItem(
            icon: _items[i].$1,
            label: _items[i].$2,
            selected: selectedIndex == i,
            onTap: () => onSelect(i),
          )),
          const Spacer(),
          // share button
          GestureDetector(
            onTap: onShare,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Share class code', style: GoogleFonts.fredoka(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),
            ),
          ),
        ]),
      )),
    );
  }
}

// ── _NavItem ──────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: selected
            ? [BoxShadow(color: Colors.black.withValues(alpha: .10),
                blurRadius: 10, offset: const Offset(0, 3))]
            : null,
      ),
      child: Row(children: [
        Icon(icon,
            color: selected ? _kVioletD : Colors.white.withValues(alpha: .8),
            size: 20),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.fredoka(
            fontSize: 14.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? _kVioletD : Colors.white.withValues(alpha: .85))),
      ]),
    ),
  );
}

// ── _CodeyDialog ──────────────────────────────────────────────────────────────
class _CodeyDialog extends StatelessWidget {
  final String title;
  final Widget child;
  const _CodeyDialog({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(title, style: GoogleFonts.fredoka(fontSize: 21,
            fontWeight: FontWeight.w700, color: _kInk),
            textAlign: TextAlign.center),
        const SizedBox(height: 18),
        child,
      ]),
    ),
  );
}

// ── _ActivityCard ─────────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final dynamic event;
  final List<dynamic> reactions;
  final void Function(String emoji) onReact;
  const _ActivityCard({required this.event, required this.reactions,
      required this.onReact});

  String _timeAgo(dynamic t) {
    if (t == null) return '';
    final dt = DateTime.tryParse(t.toString());
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours   < 1) return '${d.inMinutes}m ago';
    if (d.inDays    < 1) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  Map<String, int> _grouped() {
    final map = <String, int>{};
    for (final r in reactions) {
      final e = r['emoji'] as String? ?? '';
      map[e] = (map[e] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final name   = event['name']   as String? ?? 'Someone';
    final gameId = event['gameId'] as String? ?? '';
    final level  = event['level']  as int?    ?? 0;
    final stars  = event['stars']  as int?    ?? 0;
    final game   = _gameLabels[gameId] ?? gameId;
    final grouped = _grouped();

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ColoredAvatar(name: name, size: 42, radius: 13),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RichText(text: TextSpan(
              style: GoogleFonts.fredoka(fontSize: 14,
                  color: const Color(0xFF333333)),
              children: [
                TextSpan(text: name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: ' completed '),
                TextSpan(text: '$game Level $level',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            )),
            const SizedBox(height: 3),
            Row(children: [
              Text('★' * stars + '☆' * (3 - stars),
                  style: const TextStyle(fontSize: 14,
                      color: Color(0xFFFFB938))),
              const SizedBox(width: 8),
              Text(_timeAgo(event['completedAt']),
                  style: GoogleFonts.fredoka(fontSize: 12, color: _kMuted)),
            ]),
          ])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          ...grouped.entries.map((e) => Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F2FB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kLine),
            ),
            child: Text('${e.key} ${e.value}',
                style: GoogleFonts.fredoka(fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          )),
          const Spacer(),
          ...['🔥', '👏', '⭐'].map((emoji) => GestureDetector(
            onTap: () => onReact(emoji),
            child: Container(
              margin: const EdgeInsets.only(left: 5),
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F2FB),
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 17)),
            ),
          )),
        ]),
      ]),
    );
  }
}
