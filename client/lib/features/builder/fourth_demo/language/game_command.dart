enum GameCommandCategory { movement, events, display, control, operators }

class GameCommand {
  final String label;
  final String insertText;
  final String detail;
  final GameCommandCategory category;
  final bool opensBlock;

  const GameCommand({
    required this.label,
    required this.insertText,
    required this.detail,
    required this.category,
    this.opensBlock = false,
  });
}
