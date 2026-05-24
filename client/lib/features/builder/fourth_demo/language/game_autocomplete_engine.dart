import 'game_language_spec.dart';

class GameAutocompleteEngine {
  const GameAutocompleteEngine();

  List<String> defaultSuggestions() {
    return <String>{
      ...GameLanguageSpec.keywords,
      ...GameLanguageSpec.keyboardConstants,
      ...GameLanguageSpec.currentSpriteCommands,
      ...GameLanguageSpec.commands.map((command) => command.label),
    }.toList();
  }

  List<String> suggestionsFor(String text, int offset) {
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

    final suggestions = defaultSuggestions()
        .where((item) => item.startsWith(prefix))
        .take(10)
        .toList();

    return suggestions;
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
