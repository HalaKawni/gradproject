import 'game_command.dart';

class GameLanguageSpec {
  const GameLanguageSpec._();

  static const keyboardConstants = <String>[
    'keyboard.left',
    'keyboard.right',
    'keyboard.up',
    'keyboard.down',
  ];

  static const keywords = <String>[
    'if',
    'else',
    'loop',
    'for',
    'in',
    'until',
    'return',
    'and',
    'or',
    'not',
    'true',
    'false',
    'yes',
    'no',
  ];

  static const currentSpriteCommands = <String>[
    '@step',
    '@jump',
    '@getX',
    '@getY',
    '@setX',
    '@setY',
    '@setRotation',
    '@getRotation',
    '@setSpeed',
    '@setAllowGravity',
    '@getDistanceFrom',
    '@show',
    '@hide',
    '@destroy',
    '@disable',
    '@enable',
    '@setScale',
    '@getScale',
    '@addAnimation',
    '@startAnimation',
    '@stopAnimation',
  ];

  static const commands = <GameCommand>[
    GameCommand(
      label: 'step',
      insertText: '@step 1',
      detail: 'Move the current sprite.',
      category: GameCommandCategory.movement,
    ),
    GameCommand(
      label: 'jump',
      insertText: '@jump()',
      detail: 'Jump upward.',
      category: GameCommandCategory.movement,
    ),
    GameCommand(
      label: 'getX',
      insertText: '@getX()',
      detail: 'Read x position.',
      category: GameCommandCategory.movement,
    ),
    GameCommand(
      label: 'getY',
      insertText: '@getY()',
      detail: 'Read y position.',
      category: GameCommandCategory.movement,
    ),
    GameCommand(
      label: 'setX',
      insertText: '@setX 100',
      detail: 'Set x position.',
      category: GameCommandCategory.movement,
    ),
    GameCommand(
      label: 'setY',
      insertText: '@setY 100',
      detail: 'Set y position.',
      category: GameCommandCategory.movement,
    ),
    GameCommand(
      label: 'setRotation',
      insertText: '@setRotation 90',
      detail: 'Set rotation in degrees.',
      category: GameCommandCategory.movement,
    ),
    GameCommand(
      label: 'getRotation',
      insertText: '@getRotation()',
      detail: 'Read rotation.',
      category: GameCommandCategory.movement,
    ),
    GameCommand(
      label: 'setSpeed',
      insertText: '@setSpeed 1',
      detail: 'Set speed multiplier.',
      category: GameCommandCategory.movement,
    ),
    GameCommand(
      label: 'setAllowGravity',
      insertText: '@setAllowGravity true',
      detail: 'Toggle gravity.',
      category: GameCommandCategory.movement,
    ),
    GameCommand(
      label: 'getDistanceFrom',
      insertText: '@getDistanceFrom spriteName',
      detail: 'Distance to another sprite.',
      category: GameCommandCategory.movement,
    ),

    GameCommand(
      label: 'onStart',
      insertText: '@onStart = () =>\n    @setX 100\n    @setY 100',
      detail: 'Run once when RUN is pressed.',
      category: GameCommandCategory.events,
      opensBlock: true,
    ),
    GameCommand(
      label: 'onKey',
      insertText:
          '@onKey = (key) =>\n    if key == keyboard.right\n        @step 1',
      detail: 'Run when a keyboard key is pressed.',
      category: GameCommandCategory.events,
      opensBlock: true,
    ),
    GameCommand(
      label: 'onCollide',
      insertText: '@onCollide spriteName, () =>\n    @destroy()',
      detail: 'Run when colliding with a sprite.',
      category: GameCommandCategory.events,
      opensBlock: true,
    ),
    GameCommand(
      label: 'onDragEnd',
      insertText: '@onDragEnd = () =>\n    @jump()',
      detail: 'Run after dragging.',
      category: GameCommandCategory.events,
      opensBlock: true,
    ),
    GameCommand(
      label: 'onCollideWithWorldBounds',
      insertText:
          '@onCollideWithWorldBounds = (directions) =>\n    if directions.down\n        @jump()',
      detail: 'Run when hitting world bounds.',
      category: GameCommandCategory.events,
      opensBlock: true,
    ),
    GameCommand(
      label: 'onSwipe',
      insertText:
          '@onSwipe = (direction) =>\n    if direction == swipe.right\n        @step 1',
      detail: 'Run on swipe.',
      category: GameCommandCategory.events,
      opensBlock: true,
    ),
    GameCommand(
      label: 'onClick',
      insertText: '@onClick = () =>\n    @jump()',
      detail: 'Run when clicked.',
      category: GameCommandCategory.events,
      opensBlock: true,
    ),
    GameCommand(
      label: 'onAnimationEnd',
      insertText: '@onAnimationEnd "animationName", () =>\n    @hide()',
      detail: 'Run when animation ends.',
      category: GameCommandCategory.events,
      opensBlock: true,
    ),
    GameCommand(
      label: 'onAnimationLoop',
      insertText: '@onAnimationLoop "animationName", () =>\n    @step 1',
      detail: 'Run when animation loops.',
      category: GameCommandCategory.events,
      opensBlock: true,
    ),
    GameCommand(
      label: 'onUpdate',
      insertText: '@onUpdate = () =>\n    ',
      detail: 'Run every frame.',
      category: GameCommandCategory.events,
      opensBlock: true,
    ),
    GameCommand(
      label: 'keyboard.left',
      insertText: 'keyboard.left',
      detail: 'Left key constant.',
      category: GameCommandCategory.events,
    ),
    GameCommand(
      label: 'keyboard.right',
      insertText: 'keyboard.right',
      detail: 'Right key constant.',
      category: GameCommandCategory.events,
    ),
    GameCommand(
      label: 'keyboard.up',
      insertText: 'keyboard.up',
      detail: 'Up key constant.',
      category: GameCommandCategory.events,
    ),
    GameCommand(
      label: 'keyboard.down',
      insertText: 'keyboard.down',
      detail: 'Down key constant.',
      category: GameCommandCategory.events,
    ),

    GameCommand(
      label: 'show',
      insertText: '@show()',
      detail: 'Show sprite.',
      category: GameCommandCategory.display,
    ),
    GameCommand(
      label: 'hide',
      insertText: '@hide()',
      detail: 'Hide sprite.',
      category: GameCommandCategory.display,
    ),
    GameCommand(
      label: 'destroy',
      insertText: '@destroy()',
      detail: 'Destroy sprite.',
      category: GameCommandCategory.display,
    ),
    GameCommand(
      label: 'disable',
      insertText: '@disable()',
      detail: 'Disable sprite.',
      category: GameCommandCategory.display,
    ),
    GameCommand(
      label: 'enable',
      insertText: '@enable()',
      detail: 'Enable sprite.',
      category: GameCommandCategory.display,
    ),
    GameCommand(
      label: 'setScale',
      insertText: '@setScale 1',
      detail: 'Set scale.',
      category: GameCommandCategory.display,
    ),
    GameCommand(
      label: 'getScale',
      insertText: '@getScale()',
      detail: 'Read scale.',
      category: GameCommandCategory.display,
    ),
    GameCommand(
      label: 'say',
      insertText: '@say "Hello!"',
      detail: 'Show a message.',
      category: GameCommandCategory.display,
    ),
    GameCommand(
      label: 'addAnimation',
      insertText: '@addAnimation "run", [0, 1, 2, 3], 8, true',
      detail: 'Register animation metadata.',
      category: GameCommandCategory.display,
    ),
    GameCommand(
      label: 'startAnimation',
      insertText: '@startAnimation "run"',
      detail: 'Start animation.',
      category: GameCommandCategory.display,
    ),
    GameCommand(
      label: 'stopAnimation',
      insertText: '@stopAnimation()',
      detail: 'Stop animation.',
      category: GameCommandCategory.display,
    ),
    GameCommand(
      label: 'game.setBackground',
      insertText: 'game.setBackground "backgroundName"',
      detail: 'Change background.',
      category: GameCommandCategory.display,
    ),

    GameCommand(
      label: 'loop',
      insertText: 'loop\n    \$cursor',
      detail: 'Repeat while running.',
      category: GameCommandCategory.control,
      opensBlock: true,
    ),
    GameCommand(
      label: 'times',
      insertText: '3.times =>\n    \$cursor',
      detail: 'Repeat N times.',
      category: GameCommandCategory.control,
      opensBlock: true,
    ),
    GameCommand(
      label: 'for',
      insertText: 'for sprite in sprites\n    sprite.step 1',
      detail: 'Loop over sprites.',
      category: GameCommandCategory.control,
      opensBlock: true,
    ),
    GameCommand(
      label: 'until',
      insertText: 'until condition\n    \$cursor',
      detail: 'Repeat until condition.',
      category: GameCommandCategory.control,
      opensBlock: true,
    ),
    GameCommand(
      label: 'function',
      insertText: 'myFunction = () =>\n    \$cursor',
      detail: 'Define a function.',
      category: GameCommandCategory.control,
      opensBlock: true,
    ),
    GameCommand(
      label: 'if',
      insertText: 'if condition\n    \$cursor',
      detail: 'Conditional block.',
      category: GameCommandCategory.control,
      opensBlock: true,
    ),
    GameCommand(
      label: 'if else',
      insertText: 'if condition\n    \$cursor\nelse\n    ',
      detail: 'Conditional with else.',
      category: GameCommandCategory.control,
      opensBlock: true,
    ),
    GameCommand(
      label: 'return',
      insertText: 'return value',
      detail: 'Return value.',
      category: GameCommandCategory.control,
    ),

    GameCommand(
      label: 'not',
      insertText: 'not',
      detail: 'Boolean not.',
      category: GameCommandCategory.operators,
    ),
    GameCommand(
      label: 'and',
      insertText: 'and',
      detail: 'Boolean and.',
      category: GameCommandCategory.operators,
    ),
    GameCommand(
      label: 'or',
      insertText: 'or',
      detail: 'Boolean or.',
      category: GameCommandCategory.operators,
    ),
    GameCommand(
      label: '==',
      insertText: '==',
      detail: 'Equals.',
      category: GameCommandCategory.operators,
    ),
    GameCommand(
      label: '<',
      insertText: '<',
      detail: 'Less than.',
      category: GameCommandCategory.operators,
    ),
    GameCommand(
      label: '>',
      insertText: '>',
      detail: 'Greater than.',
      category: GameCommandCategory.operators,
    ),
    GameCommand(
      label: '+=',
      insertText: '+=',
      detail: 'Add assignment.',
      category: GameCommandCategory.operators,
    ),
    GameCommand(
      label: '-=',
      insertText: '-=',
      detail: 'Subtract assignment.',
      category: GameCommandCategory.operators,
    ),
  ];

  static List<GameCommand> byCategory(GameCommandCategory category) {
    return commands.where((command) => command.category == category).toList();
  }

  static GameCommand commandByLabel(String label) {
    return commands.firstWhere((command) => command.label == label);
  }
}
