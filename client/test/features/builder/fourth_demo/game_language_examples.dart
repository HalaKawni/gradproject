import 'package:client/features/builder/fourth_demo/language/game_parser.dart';
import 'package:client/features/builder/fourth_demo/models/fourth_demo_project.dart';
import 'package:flutter_test/flutter_test.dart';

const fourthDemoLanguageExample = '''
@onStart = () =>
    @setX 100
    @setY 200
    @say "Game started"
    @setScale 1.5
    @addAnimation "run", [0, 1, 2, 3], 8, true
    @startAnimation "run"
    for sprite in sprites
        sprite.show()

@onKey = (key) =>
    if key == keyboard.right
        moveRight()
    else
        @say "Use the right arrow"

@onKey = (key) =>
    if key == keyboard.up
        @jump()

@onUpdate = () =>
    if @getX() > 500
        @setX 0

@onCollide banana, () =>
    @say "You got the banana"
    banana.hide()
    game.setBackground "forest"

moveRight = () =>
    if @getX() > 500
        return
    @step 1
''';

const invalidMissingArrow = '''
@onKey = (key)
    @step 1
''';

const invalidIndent = '''
@onStart = () =>
@step 1
''';

const invalidNumber = '''
@onStart = () =>
    @setX abc
''';

void main() {
  test('parses valid fourth demo language example', () {
    final parser = const GameParser();
    final project = FourthDemoProject.sample();

    final valid = parser.parse(
      code: fourthDemoLanguageExample,
      targetSpriteId: project.selectedSpriteId,
      project: project,
    );

    expect(valid.diagnostic?.displayMessage, isNull);
    expect(valid.isValid, isTrue);
  });

  test('reports invalid fourth demo language examples', () {
    final parser = const GameParser();
    final project = FourthDemoProject.sample();

    for (final code in <String>[
      invalidMissingArrow,
      invalidIndent,
      invalidNumber,
    ]) {
      final result = parser.parse(
        code: code,
        targetSpriteId: project.selectedSpriteId,
        project: project,
      );
      expect(result.isValid, isFalse);
      expect(result.diagnostic, isNotNull);
    }
  });
}
