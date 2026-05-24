import 'package:client/features/builder/fourth_demo/language/game_code_indenter.dart';
import 'package:client/features/builder/fourth_demo/language/game_language_spec.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const indenter = GameCodeIndenter();

  TextEditingValue enterAtCaret(String input) {
    final offset = input.indexOf('|');
    final text = input.replaceFirst('|', '');

    return indenter.applyEnter(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: offset),
      ),
    );
  }

  String withCaret(TextEditingValue value) {
    return value.text.replaceRange(
      value.selection.baseOffset,
      value.selection.baseOffset,
      '|',
    );
  }

  TextEditingValue backspaceAtCaret(String input) {
    final offset = input.indexOf('|');
    final oldText = input.replaceFirst('|', '');
    final newText = oldText.replaceRange(offset - 1, offset, '');

    return indenter.applyScopeBackspace(
      oldValue: TextEditingValue(
        text: oldText,
        selection: TextSelection.collapsed(offset: offset),
      ),
      newValue: TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: offset - 1),
      ),
    );
  }

  test('enter indents after event line', () {
    expect(
      withCaret(enterAtCaret('@onKey = (key) =>|')),
      '@onKey = (key) =>\n    |',
    );
  });

  test('backspace at indentation moves to parent scope', () {
    expect(
      withCaret(
        backspaceAtCaret(
          '@onKey = (key) =>\n'
          '    if key == keyboard.right\n'
          '        |@step 1',
        ),
      ),
      '@onKey = (key) =>\n'
      '    if key == keyboard.right\n'
      '    |@step 1',
    );
  });

  test('enter indents after nested if line', () {
    expect(
      withCaret(
        enterAtCaret('@onKey = (key) =>\n    if key == keyboard.right|'),
      ),
      '@onKey = (key) =>\n    if key == keyboard.right\n        |',
    );
  });

  test('enter preserves nested command indentation', () {
    expect(
      withCaret(
        enterAtCaret(
          '@onKey = (key) =>\n'
          '    if key == keyboard.right\n'
          '        @step 1|',
        ),
      ),
      '@onKey = (key) =>\n'
      '    if key == keyboard.right\n'
      '        @step 1\n'
      '        |',
    );
  });

  test('enter indents after loop-like lines', () {
    expect(withCaret(enterAtCaret('loop|')), 'loop\n    |');
    expect(withCaret(enterAtCaret('3.times =>|')), '3.times =>\n    |');
    expect(
      withCaret(enterAtCaret('for sprite in sprites|')),
      'for sprite in sprites\n    |',
    );
  });

  test('step command inserts inside an if block', () {
    const code = '@onKey = (key) =>\n    if key == keyboard.right\n';
    final insertion = indenter.insertCommand(
      code: code,
      start: code.length,
      end: code.length,
      command: GameLanguageSpec.commandByLabel('step'),
    );

    expect(
      insertion.text,
      '@onKey = (key) =>\n    if key == keyboard.right\n        @step 1',
    );
    expect(insertion.cursorOffset, insertion.text.length);
  });

  test('step command after if line inserts on the next nested line', () {
    const code = '@onKey = (key) =>\n    if key == keyboard.right';
    final insertion = indenter.insertCommand(
      code: code,
      start: code.length,
      end: code.length,
      command: GameLanguageSpec.commandByLabel('step'),
    );

    expect(
      insertion.text,
      '@onKey = (key) =>\n    if key == keyboard.right\n        @step 1',
    );
  });

  test('event command inserts at top level from inside another event', () {
    const code = '@onKey = (key) =>\n    ';
    final insertion = indenter.insertCommand(
      code: code,
      start: code.length,
      end: code.length,
      command: GameLanguageSpec.commandByLabel('onCollide'),
    );

    expect(
      insertion.text,
      '@onKey = (key) =>\n@onCollide spriteName, () =>\n    @destroy()',
    );
  });

  test('loop snippet is indented inside current block and keeps nested body', () {
    const code = '@onKey = (key) =>\n    ';
    final insertion = indenter.insertCommand(
      code: code,
      start: code.length,
      end: code.length,
      command: GameLanguageSpec.commandByLabel('loop'),
    );

    expect(insertion.text, '@onKey = (key) =>\n    loop\n        ');
    expect(insertion.cursorOffset, insertion.text.length);
  });
}
