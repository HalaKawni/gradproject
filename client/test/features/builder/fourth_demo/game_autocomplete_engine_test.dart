import 'package:client/features/builder/fourth_demo/language/game_autocomplete_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = GameAutocompleteEngine();

  test('does not suggest anything on empty lines', () {
    expect(engine.suggestionsFor('@onKey = (key) =>\n    ', 22), isEmpty);
  });

  test('suggests sprite commands after at sign', () {
    expect(engine.suggestionsFor('@', 1), contains('@step'));
  });

  test('suggests matching commands for a prefix', () {
    final suggestions = engine.suggestionsFor('st', 2);

    expect(suggestions, contains('step'));
    expect(suggestions, contains('stopAnimation'));
    expect(suggestions, isNot(contains('here')));
  });

  test('suggests keyboard constants only for keyboard prefix', () {
    expect(
      engine.suggestionsFor('keyboard.r', 'keyboard.r'.length),
      equals(<String>['keyboard.right']),
    );
  });

  test('does not fall back to unrelated defaults', () {
    expect(engine.suggestionsFor('unknownWord', 'unknownWord'.length), isEmpty);
  });
}
