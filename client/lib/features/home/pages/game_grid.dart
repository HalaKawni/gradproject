import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_background.dart';

class GameGridPage extends StatefulWidget {
  const GameGridPage({super.key});

  @override
  State<GameGridPage> createState() => _GameGridPageState();
}

class _GameGridPageState extends State<GameGridPage> {
  static const int cols = 8;
  static const int rows = 6;

  int _charX = 0;
  int _charY = 0;
  int _direction = 0;

  final int _goalX = 6;
  final int _goalY = 3;

  final List<Offset> _obstacles = [
    const Offset(2, 1),
    const Offset(2, 2),
    const Offset(2, 3),
    const Offset(5, 1),
    const Offset(5, 2),
    const Offset(5, 4),
  ];

  final List<String> _commands = [];

  bool _isRunning = false;
  bool _won = false;
  bool _failed = false;
  String _statusMessage = '';

  bool _isObstacle(int x, int y) {
    return _obstacles.any((o) => o.dx == x && o.dy == y);
  }

  bool _isInBounds(int x, int y) {
    return x >= 0 && x < cols && y >= 0 && y < rows;
  }

  void _addCommand(String cmd) {
    if (_isRunning) return;
    setState(() => _commands.add(cmd));
  }

  void _removeCommand(int index) {
    if (_isRunning) return;
    setState(() => _commands.removeAt(index));
  }

  void _reset() {
    setState(() {
      _charX = 0;
      _charY = 0;
      _direction = 0;
      _commands.clear();
      _isRunning = false;
      _won = false;
      _failed = false;
      _statusMessage = '';
    });
  }

  Future<void> _runCommands() async {
    if (_isRunning || _commands.isEmpty) return;
    setState(() {
      _isRunning = true;
      _won = false;
      _failed = false;
      _statusMessage = '';
      _charX = 0;
      _charY = 0;
      _direction = 0;
    });

    for (final cmd in _commands) {
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        switch (cmd) {
          case 'move':
            int nx = _charX, ny = _charY;
            if (_direction == 0) {
              nx++;
            } else if (_direction == 1) ny++;
            else if (_direction == 2) nx--;
            else if (_direction == 3) ny--;

            if (!_isInBounds(nx, ny)) {
              _failed = true;
              _statusMessage = 'Oops! Walked off the grid!';
            } else if (_isObstacle(nx, ny)) {
              _failed = true;
              _statusMessage = 'Oops! Hit a wall!';
            } else {
              _charX = nx;
              _charY = ny;
            }
            break;
          case 'turn_right':
            _direction = (_direction + 1) % 4;
            break;
          case 'turn_left':
            _direction = (_direction + 3) % 4;
            break;
        }
      });

      if (_failed) break;

      if (_charX == _goalX && _charY == _goalY) {
        setState(() {
          _won = true;
          _statusMessage = '🎉 You reached the goal!';
        });
        break;
      }
    }

    if (!_won && !_failed) {
      setState(() {
        _statusMessage = 'Commands finished — keep going!';
      });
    }

    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 252, 183, 199),
        title: Text(
          'Block Coding Game',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: const Color.fromARGB(255, 202, 97, 128),
          ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ── BACKGROUND ──
          const GameBackground(),

          // ── GAME CONTENT ──
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── LEFT: GRID ──
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GAME GRID',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGrid(),
                      const SizedBox(height: 16),
                      if (_statusMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _won
                                ? const Color(0xFFDFF5E1)
                                : _failed
                                    ? const Color(0xFFFFEBEE)
                                    : const Color(0xFFFFF9C4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _won
                                  ? const Color(0xFF81C784)
                                  : _failed
                                      ? const Color(0xFFE57373)
                                      : const Color(0xFFFFD54F),
                            ),
                          ),
                          child: Text(
                            _statusMessage,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _won
                                  ? const Color(0xFF2E7D32)
                                  : _failed
                                      ? const Color(0xFFC62828)
                                      : const Color(0xFF795548),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // ── MIDDLE: BLOCK PALETTE ──
                SizedBox(
                  width: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BLOCKS',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PaletteBlock(
                        label: '▶  Move Forward',
                        color: const Color(0xFF4A9FD4),
                        onTap: () => _addCommand('move'),
                      ),
                      const SizedBox(height: 8),
                      _PaletteBlock(
                        label: '↻  Turn Right',
                        color: const Color(0xFF6DB84A),
                        onTap: () => _addCommand('turn_right'),
                      ),
                      const SizedBox(height: 8),
                      _PaletteBlock(
                        label: '↺  Turn Left',
                        color: const Color(0xFFE8A838),
                        onTap: () => _addCommand('turn_left'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // ── RIGHT: COMMAND QUEUE + BUTTONS ──
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR PROGRAM',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(minHeight: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFDDDDDD)),
                        ),
                        child: _commands.isEmpty
                            ? Center(
                                child: Text(
                                  'Tap blocks to add\ncommands here',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: const Color(0xFFAAAAAA),
                                  ),
                                ),
                              )
                            : Column(
                                children: List.generate(
                                  _commands.length,
                                  (i) => _CommandItem(
                                    index: i + 1,
                                    command: _commands[i],
                                    onDelete: () => _removeCommand(i),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isRunning ? null : _runCommands,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            'RUN',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6DB84A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            'RESET',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    const cellSize = 64.0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(cols, (col) {
              final isChar = _charX == col && _charY == row;
              final isGoal = _goalX == col && _goalY == row;
              final isObstacle = _isObstacle(col, row);
              final isEven = (row + col) % 2 == 0;

              return Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: isObstacle
                      ? const Color(0xFF8B6347)
                      : isEven
                          ? const Color(0xFF90C97A)
                          : const Color(0xFF7DBF68),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.08),
                    width: 0.5,
                  ),
                ),
                child: isChar
                    ? Center(child: _buildCharacter())
                    : isGoal
                        ? Center(
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFA000),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(Icons.star,
                                  color: Colors.white, size: 22),
                            ),
                          )
                        : isObstacle
                            ? const Center(
                                child: Icon(Icons.close,
                                    color: Colors.white54, size: 20))
                            : null,
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildCharacter() {
    final arrows = ['→', '↓', '←', '↑'];
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF4A7DBF),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Center(
        child: Text(
          arrows[_direction],
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }
}

// ── PALETTE BLOCK ──
class _PaletteBlock extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PaletteBlock({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── COMMAND ITEM ──
class _CommandItem extends StatelessWidget {
  final int index;
  final String command;
  final VoidCallback onDelete;

  const _CommandItem({
    required this.index,
    required this.command,
    required this.onDelete,
  });

  String get _label {
    switch (command) {
      case 'move':
        return '▶  Move Forward';
      case 'turn_right':
        return '↻  Turn Right';
      case 'turn_left':
        return '↺  Turn Left';
      default:
        return command;
    }
  }

  Color get _color {
    switch (command) {
      case 'move':
        return const Color(0xFF4A9FD4);
      case 'turn_right':
        return const Color(0xFF6DB84A);
      case 'turn_left':
        return const Color(0xFFE8A838);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close,
                size: 16, color: Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }
}