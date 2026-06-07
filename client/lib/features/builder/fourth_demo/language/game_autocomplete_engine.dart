import 'game_language_spec.dart';
import '../models/fourth_demo_project.dart';

class GameAutocompleteEngine {
  const GameAutocompleteEngine();

  static const gameCommands = <String>[
    'game.setBackground',
    'game.setWidth',
    'game.setHeight',
    'game.setSize',
    'game.setGravity',
    'game.setPhysics',
    'game.setCameraTarget',
    'game.getWidth()',
    'game.getHeight()',
    'game.getGravity()',
    'game.getBackground()',
    'game.getPhysics()',
  ];
  static const directionsMembers = <String>['left', 'right', 'up', 'down'];
  static const directionValues = <String>[
    '"left"',
    '"right"',
    '"up"',
    '"down"',
  ];
  static const soundMembers = <String>[
    'play',
    'stop',
    'pause',
    'resume',
    'setVolume',
    'setLoop',
    'isPlaying',
    'getVolume',
  ];
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
  static const _commonWidgetMembers = <String>[
    'show',
    'hide',
    'setText',
    'setX',
    'setY',
    'setOpacity',
    'isVisible',
  ];
  static const _counterWidgetMembers = <String>[
    ..._commonWidgetMembers,
    'setValue',
    'add',
    'subtract',
    'reset',
    'getValue',
  ];
  static const _textWidgetMembers = <String>[
    ..._commonWidgetMembers,
    'append',
    'clear',
    'getText',
  ];
  static const _timerWidgetMembers = <String>[
    ..._commonWidgetMembers,
    'start',
    'stop',
    'reset',
    'setDuration',
    'setValue',
    'getValue',
  ];
  static const _clockWidgetMembers = <String>[
    ..._commonWidgetMembers,
    'start',
    'stop',
    'reset',
    'getValue',
  ];
  static const _buttonWidgetMembers = <String>[
    ..._commonWidgetMembers,
    'enable',
    'disable',
  ];
  static const _dialogWidgetMembers = <String>[
    ..._commonWidgetMembers,
    'setTitle',
    'setButtonText',
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
    final contextual = _contextualValueSuggestions(text, offset, prefix);
    if (contextual.isNotEmpty) {
      return contextual;
    }
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

    if (prefix == 'directions.' || prefix.startsWith('directions.')) {
      final memberPrefix = prefix.substring('directions.'.length);
      return directionsMembers
          .where((item) => item.startsWith(memberPrefix))
          .map((item) => 'directions.$item')
          .toList();
    }

    final receiverPrefix = RegExp(
      r'^([A-Za-z_]\w*)\.(\w*)$',
    ).firstMatch(prefix);
    if (receiverPrefix != null) {
      final receiver = receiverPrefix.group(1)!;
      final memberPrefix = receiverPrefix.group(2)!;
      final widgetMembers = _widgetMembersFor(receiver, project);
      if (widgetMembers != null) {
        return widgetMembers
            .where((item) => item.startsWith(memberPrefix))
            .map((item) => '$receiver.$item')
            .toList();
      }
      if (_isKnownSoundReceiver(receiver, project)) {
        return soundMembers
            .where((item) => item.startsWith(memberPrefix))
            .map((item) => '$receiver.$item')
            .toList();
      }
      if (_isKnownSpriteReceiver(receiver, text, offset, project)) {
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
      if (project != null) ...project.widgets.map((widget) => widget.name),
      if (project != null) ...project.widgets.map((widget) => widget.id),
      if (project != null) ...project.sounds.map((sound) => sound.name),
      if (project != null) ...project.sounds.map((sound) => sound.id),
      ..._functionNames(text).map((name) => '$name()'),
      'game',
      'key',
      'direction',
      'directions',
      ..._loopVariablesBefore(text, offset),
      'sprite in sprites',
    }.where((item) => item.startsWith(prefix)).take(10).toList();

    return suggestions;
  }

  bool _isKnownSpriteReceiver(
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

  List<String>? _widgetMembersFor(String receiver, FourthDemoProject? project) {
    if (project == null) {
      return null;
    }
    final widget = project.widgets
        .where((item) => item.id == receiver || item.name == receiver)
        .firstOrNull;
    if (widget == null) {
      return null;
    }
    return switch (widget.type) {
      FourthDemoWidgetKind.counter => _counterWidgetMembers,
      FourthDemoWidgetKind.text => _textWidgetMembers,
      FourthDemoWidgetKind.timer => _timerWidgetMembers,
      FourthDemoWidgetKind.clock => _clockWidgetMembers,
      FourthDemoWidgetKind.button => _buttonWidgetMembers,
      FourthDemoWidgetKind.dialog => _dialogWidgetMembers,
    };
  }

  bool _isKnownSoundReceiver(String receiver, FourthDemoProject? project) {
    if (project == null) {
      return false;
    }
    return project.sounds.any(
      (sound) => sound.id == receiver || sound.name == receiver,
    );
  }

  List<String> _contextualValueSuggestions(
    String text,
    int offset,
    String prefix,
  ) {
    final before = text.substring(0, offset.clamp(0, text.length).toInt());
    if (RegExp(r'key\s*==\s*[\w.]*$').hasMatch(before)) {
      return GameLanguageSpec.keyboardConstants
          .where((item) => item.startsWith(prefix))
          .toList();
    }
    if (RegExp(r'direction\s*==\s*"?\w*$').hasMatch(before)) {
      return directionValues
          .where(
            (item) =>
                item.startsWith(prefix) ||
                item.replaceAll('"', '').startsWith(prefix),
          )
          .toList();
    }
    return const <String>[];
  }

  Set<String> _functionNames(String text) {
    return RegExp(
      r'^([A-Za-z_]\w*)\s*=\s*\(\s*\)\s*=>\s*$',
      multiLine: true,
    ).allMatches(text).map((match) => match.group(1)!).toSet();
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
