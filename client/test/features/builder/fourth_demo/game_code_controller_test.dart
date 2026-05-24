import 'package:client/features/builder/fourth_demo/language/game_code_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('autocomplete replaces typed at sign instead of duplicating it', () {
    final controller = GameCodeController(text: '@');
    controller.selection = const TextSelection.collapsed(offset: 1);
    controller.popupController.show(const <String>['@step']);

    controller.insertSelectedWord();

    expect(controller.text, '@step');
    expect(controller.selection.baseOffset, '@step'.length);
  });

  test('autocomplete replaces partial at command', () {
    final controller = GameCodeController(text: '@st');
    controller.selection = const TextSelection.collapsed(offset: 3);
    controller.popupController.show(const <String>['@step']);

    controller.insertSelectedWord();

    expect(controller.text, '@step');
  });

  test('autocomplete replaces keyboard prefix', () {
    final controller = GameCodeController(text: 'keyboard.r');
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    controller.popupController.show(const <String>['keyboard.right']);

    controller.insertSelectedWord();

    expect(controller.text, 'keyboard.right');
  });
}
