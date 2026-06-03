import 'package:client/features/builder/fourth_demo/controllers/fourth_demo_controller.dart';
import 'package:client/features/builder/fourth_demo/language/game_runtime.dart';
import 'package:client/features/builder/fourth_demo/models/fourth_demo_project.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FourthDemoController controllerWithCode(String code) {
    final controller = FourthDemoController();
    controller.updateSelectedCode(code, notify: false);
    expect(controller.runCode(), isTrue);
    return controller;
  }

  FourthDemoSprite player(FourthDemoController controller) {
    return controller.project.sprites.firstWhere((sprite) => sprite.id == 'polar');
  }

  group('keyboard movement runtime', () {
    test('right arrow and D move right continuously while held', () {
      const code = '''
@onKey = (key) =>
    if key == keyboard.right
        @setRotation 0
        @step 1
''';
      final controller = controllerWithCode(code);
      final startX = player(controller).x;

      controller.handleKeyDown(LogicalKeyboardKey.arrowRight);
      controller.handleUpdate(0.2);
      expect(player(controller).x, greaterThan(startX));
      final afterRight = player(controller).x;
      controller.handleKeyUp(LogicalKeyboardKey.arrowRight);

      controller.handleKeyDown(LogicalKeyboardKey.keyD);
      controller.handleUpdate(0.2);
      expect(player(controller).x, greaterThan(afterRight));
    });

    test('left, up, and down conditions move only for matching keys', () {
      const code = '''
@onKey = (key) =>
    if key == keyboard.left
        @setRotation 180
        @step 1
    if key == keyboard.up
        @setRotation -90
        @step 1
    if key == keyboard.down
        @setRotation 90
        @step 1
''';
      final controller = controllerWithCode(code);
      final start = player(controller);

      controller.handleKeyDown(LogicalKeyboardKey.keyA);
      controller.handleUpdate(0.2);
      expect(player(controller).x, lessThan(start.x));
      expect(player(controller).y, start.y);
      controller.handleKeyUp(LogicalKeyboardKey.keyA);

      controller.handleKey(LogicalKeyboardKey.keyW);
      expect(player(controller).y, start.y - FourthDemoController.stepSize);

      controller.handleKey(LogicalKeyboardKey.keyS);
      expect(player(controller).y, start.y);
    });

    test('onStart runs once when code starts', () {
      final controller = controllerWithCode('''
@onStart = () =>
    @setX 100
    @setY 100
''');

      expect(player(controller).x, 100);
      expect(player(controller).y, 100);
    });

    test('else branch runs for another accepted key', () {
      final controller = controllerWithCode('''
@onKey = (key) =>
    if key == keyboard.up
        @setRotation -90
        @step 1
    else
        @say "wrong key"
''');
      final startY = player(controller).y;

      controller.handleKey(LogicalKeyboardKey.arrowUp);
      expect(player(controller).y, startY - FourthDemoController.stepSize);

      controller.handleKey(LogicalKeyboardKey.arrowRight);
      expect(controller.statusMessage, 'wrong key');
    });

    test('setX and setY clamp using sprite size', () {
      final controller = controllerWithCode('''
@onStart = () =>
    @setX 9999
    @setY 9999
''');
      final sprite = player(controller);

      expect(sprite.x, controller.project.settings.worldWidth - sprite.width);
      expect(sprite.y, controller.project.settings.worldHeight - sprite.height);
    });

    test('jump uses velocity and lands back on the starting ground', () {
      final controller = controllerWithCode('''
@onKey = (key) =>
    if key == keyboard.up
        @jump()
''');
      final startY = player(controller).y;

      controller.handleKeyDown(LogicalKeyboardKey.arrowUp);
      controller.handleUpdate(0.1);
      expect(player(controller).y, lessThan(startY));

      for (var i = 0; i < 40; i += 1) {
        controller.handleUpdate(1 / 60);
      }
      expect(player(controller).y, startY);
    });

    test('right movement while jumping applies horizontal air control', () {
      final controller = controllerWithCode('''
@onKey = (key) =>
    if key == keyboard.up
        @jump()
    if key == keyboard.right
        @setRotation 0
        @step 1
''');
      final startX = player(controller).x;

      controller.handleKeyDown(LogicalKeyboardKey.arrowUp);
      controller.handleUpdate(0.1);
      controller.handleKeyDown(LogicalKeyboardKey.arrowRight);
      controller.handleUpdate(0.1);

      expect(player(controller).x, greaterThan(startX));
      expect(player(controller).y, lessThan(player(controller).startY));
    });

    test('held right key keeps moving and held left key flips the player', () {
      final controller = controllerWithCode('''
@onKey = (key) =>
    if key == keyboard.right
        @setRotation 0
        @step 1
    if key == keyboard.left
        @setRotation 180
        @step 1
''');
      final startX = player(controller).x;

      controller.handleKeyDown(LogicalKeyboardKey.arrowRight);
      controller.handleUpdate(0.13);
      expect(player(controller).x, greaterThan(startX));
      expect(player(controller).facing, FourthDemoSpriteFacing.right);

      controller.handleKeyUp(LogicalKeyboardKey.arrowRight);
      controller.handleKeyDown(LogicalKeyboardKey.arrowLeft);
      controller.handleUpdate(0.13);
      expect(player(controller).facing, FourthDemoSpriteFacing.left);
    });

    test('custom collectible collision code prevents automatic collection', () {
      final controller = FourthDemoController();
      controller.selectSprite('banana');
      controller.updateSelectedCode('''
@onCollide polar, () =>
    @setX 100
    @setY 100
''', notify: false);
      controller.selectSprite('polar');
      controller.updateSelectedCode('''
@onStart = () =>
    @setX 462
    @setY 286
''', notify: false);

      expect(controller.runCode(), isTrue);
      controller.handleUpdate();

      final banana = controller.project.sprites.firstWhere(
        (sprite) => sprite.id == 'banana',
      );
      expect(banana.x, 100);
      expect(banana.y, 100);
      expect(banana.visible, isTrue);
      expect(controller.exerciseComplete, isFalse);
    });

    test('stop restores a sprite destroyed during the run', () {
      final controller = FourthDemoController();
      controller.selectSprite('banana');
      controller.updateSelectedCode('''
@onCollide polar, () =>
    @destroy()
''', notify: false);
      controller.selectSprite('polar');
      controller.updateSelectedCode('''
@onStart = () =>
    @setX 462
    @setY 286
''', notify: false);

      expect(controller.runCode(), isTrue);
      controller.handleUpdate();

      var banana = controller.project.sprites.firstWhere(
        (sprite) => sprite.id == 'banana',
      );
      expect(banana.destroyed, isTrue);
      expect(banana.visible, isFalse);
      expect(banana.enabled, isFalse);

      controller.stop();
      banana = controller.project.sprites.firstWhere(
        (sprite) => sprite.id == 'banana',
      );
      expect(banana.destroyed, isFalse);
      expect(banana.visible, isTrue);
      expect(banana.enabled, isTrue);
      expect(banana.x, banana.startX);
      expect(banana.y, banana.startY);
    });

    test('stop restores the exact project state from before run', () {
      final controller = FourthDemoController();
      controller.updateSettings(
        controller.project.settings.copyWith(background: 'forest'),
      );
      controller.updateSelectedCode('''
@onStart = () =>
    @setX 123
    @setY 111
    @hide()
    @setScale 2
    @say "changed"
    game.setBackground "desert"
''', notify: false);
      final beforeRun = controller.project.encode();

      expect(controller.runCode(), isTrue);
      expect(player(controller).x, 123);
      expect(player(controller).visible, isFalse);
      expect(player(controller).scale, 2);
      expect(controller.project.settings.background, 'desert');
      expect(controller.speechTextFor('polar'), 'changed');

      controller.stop();
      expect(controller.project.encode(), beforeRun);
      expect(controller.speechTextFor('polar'), isNull);
      expect(controller.exerciseComplete, isFalse);
      expect(controller.isPlaying, isFalse);
    });

    test('say shows temporary speech for the current sprite', () {
      final controller = controllerWithCode('''
@onStart = () =>
    @say "Hello!"
''');

      expect(controller.speechTextFor('polar'), 'Hello!');
      controller.handleUpdate(1.2);
      expect(controller.speechTextFor('polar'), 'Hello!');
      controller.handleUpdate(1.4);
      expect(controller.speechTextFor('polar'), isNull);
    });

    test('stop clears active speech bubbles', () {
      final controller = controllerWithCode('''
@onStart = () =>
    @say "Still here"
''');

      expect(controller.speechTextFor('polar'), 'Still here');
      controller.stop();
      expect(controller.speechTextFor('polar'), isNull);
    });

    test('sprite code is stored separately by sprite id', () {
      final controller = FourthDemoController();
      const polarCode = '''
@onKey = (key) =>
    @step 1
''';
      const bananaCode = '''
@onCollide polar, () =>
    @say "banana"
''';

      controller.updateCodeForSprite('polar', polarCode, notify: false);
      controller.updateCodeForSprite('banana', bananaCode, notify: false);
      controller.selectSprite('polar');
      expect(controller.selectedCode, polarCode);

      controller.selectSprite('banana');
      expect(controller.selectedCode, bananaCode);

      controller.selectSprite('polar');
      expect(controller.selectedCode, polarCode);
    });
  });

  group('condition evaluation', () {
    const runtime = GameRuntime();

    GameRuntimeContext context(LogicalKeyboardKey key) {
      return GameRuntimeContext(
        project: FourthDemoProject.sample(),
        currentSpriteId: 'polar',
        key: key,
      );
    }

    test('keyboard aliases match direction constants', () {
      expect(runtime.evaluateCondition('key == keyboard.right', context(LogicalKeyboardKey.arrowRight)), isTrue);
      expect(runtime.evaluateCondition('key == keyboard.right', context(LogicalKeyboardKey.keyD)), isTrue);
      expect(runtime.evaluateCondition('key == keyboard.left', context(LogicalKeyboardKey.keyA)), isTrue);
      expect(runtime.evaluateCondition('key == keyboard.up', context(LogicalKeyboardKey.keyW)), isTrue);
      expect(runtime.evaluateCondition('key == keyboard.down', context(LogicalKeyboardKey.keyS)), isTrue);
    });

    test('not equals works for keys', () {
      expect(runtime.evaluateCondition('key != keyboard.right', context(LogicalKeyboardKey.keyA)), isTrue);
      expect(runtime.evaluateCondition('key != keyboard.right', context(LogicalKeyboardKey.keyD)), isFalse);
    });
  });
}
