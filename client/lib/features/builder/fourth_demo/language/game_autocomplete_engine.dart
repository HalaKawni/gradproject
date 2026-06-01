import 'game_language_spec.dart';
import '../models/fourth_demo_project.dart';

class GameAutocompleteEngine {
  const GameAutocompleteEngine();

  static const gameCommands = <String>['game.setBackground'];
  static const spriteCommandMembers = <String>[
    'step',
    'jump',
    'setX',
    'setY',
    'setRotation',
    'setSpeed',
    'setAllowGravity',
    'show',
    'hide',
    'destroy',
    'disable',
    'enable',
    'setScale',
    'say',
    'addAnimation',
    'startAnimation',
    'stopAnimation',
  ];

  List<String> defaultSuggestions() {
    return <String>{
      ...GameLanguageSpec.keywords,
      ...GameLanguageSpec.keyboardConstants,
      ...GameLanguageSpec.currentSpriteCommands,
      ...gameCommands,
      ...GameLanguageSpec.commands.map((command) => command.label),
    }.toList();
  }

  List<String> suggestionsFor(
    String text,
    int offset, {
    FourthDemoProject? project,
  }) {
    final prefix = _prefixAt(text, offset);
    if (prefix.isEmpty) {
      return const <String>[];
    }

    if (prefix == 'keyboard.' || prefix.startsWith('keyboard.')) {
      return GameLanguageSpec.keyboardConstants
          .where((item) => item.startsWith(prefix))
          .toList();
    }

    if (prefix == '@' || prefix.startsWith('@')) {
      return GameLanguageSpec.currentSpriteCommands
          .where((item) => item.startsWith(prefix))
          .toList();
    }

    if (prefix == 'game.' || prefix.startsWith('game.')) {
      return gameCommands.where((item) => item.startsWith(prefix)).toList();
    }

    final receiverPrefix = RegExp(
      r'^([A-Za-z_]\w*)\.(\w*)$',
    ).firstMatch(prefix);
    if (receiverPrefix != null) {
      final receiver = receiverPrefix.group(1)!;
      if (_isKnownReceiver(receiver, text, offset, project)) {
        final memberPrefix = receiverPrefix.group(2)!;
        return spriteCommandMembers
            .where((item) => item.startsWith(memberPrefix))
            .map((item) => '$receiver.$item')
            .toList();
      }
    }

    final suggestions = <String>{
      ...defaultSuggestions(),
      if (project != null) ...project.sprites.map((sprite) => sprite.name),
      if (project != null) ...project.sprites.map((sprite) => sprite.id),
      ..._loopVariablesBefore(text, offset),
      'sprite in sprites',
    }.where((item) => item.startsWith(prefix)).take(10).toList();

    return suggestions;
  }

  bool _isKnownReceiver(
    String receiver,
    String text,
    int offset,
    FourthDemoProject? project,
  ) {
    if (_loopVariablesBefore(text, offset).contains(receiver)) {
      return true;
    }
    if (project == null) {
      return false;
    }
    return project.sprites.any(
      (sprite) => sprite.id == receiver || sprite.name == receiver,
    );
  }

  Set<String> _loopVariablesBefore(String text, int offset) {
    final before = text.substring(0, offset.clamp(0, text.length).toInt());
    return RegExp(
      r'^(\s*)for\s+([A-Za-z_]\w*)\s+in\s+sprites\s*$',
      multiLine: true,
    ).allMatches(before).map((match) => match.group(2)!).toSet();
  }

  String _prefixAt(String text, int offset) {
    if (offset < 0 || offset > text.length) {
      return '';
    }

    var start = offset;
    while (start > 0) {
      final char = text[start - 1];
      if (!RegExp(r'[\w@.]').hasMatch(char)) {
        break;
      }
      start -= 1;
    }

    return text.substring(start, offset);
  }
}
