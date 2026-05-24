import 'dart:async';

import 'package:flutter/material.dart';

class PopupController extends ChangeNotifier {
  static const itemExtent = 24.0;

  var suggestions = const <String>[];
  var _selectedIndex = 0;
  var shouldShow = false;
  var enabled = true;

  final scrollController = ScrollController();

  /// Called when an active list item is selected for insertion.
  late final void Function() onCompletionSelected;

  PopupController({required this.onCompletionSelected}) : super();

  set selectedIndex(int value) {
    _selectedIndex = value;
    notifyListeners();
  }

  int get selectedIndex => _selectedIndex;

  void show(List<String> suggestions) {
    if (!enabled) {
      return;
    }

    this.suggestions = suggestions;
    _selectedIndex = 0;
    shouldShow = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
    });
    notifyListeners();
  }

  void hide() {
    shouldShow = false;
    notifyListeners();
  }

  /// Changes the selected item on keyboard arrow presses.
  void scrollByArrow(ScrollDirection direction) {
    if (suggestions.isEmpty) {
      hide();
      return;
    }

    if (direction == ScrollDirection.up) {
      selectedIndex =
          (selectedIndex - 1 + suggestions.length) % suggestions.length;
    } else {
      selectedIndex = (selectedIndex + 1) % suggestions.length;
    }
    _scrollSelectedIntoView();
    notifyListeners();
  }

  String getSelectedWord() => suggestions[selectedIndex];

  void _scrollSelectedIntoView() {
    void scroll() {
      if (!scrollController.hasClients) {
        return;
      }

      final position = scrollController.position;
      final itemTop = selectedIndex * itemExtent;
      final itemBottom = itemTop + itemExtent;
      final viewportTop = position.pixels;
      final viewportBottom = viewportTop + position.viewportDimension;
      double? target;

      if (itemTop < viewportTop) {
        target = itemTop;
      } else if (itemBottom > viewportBottom) {
        target = itemBottom - position.viewportDimension;
      }

      if (target == null) {
        return;
      }

      final clampedTarget = target.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      unawaited(
        scrollController.animateTo(
          clampedTarget,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        ),
      );
    }

    if (scrollController.hasClients) {
      scroll();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => scroll());
    }
  }
}

/// Possible directions of completions list navigation
enum ScrollDirection {
  up,
  down,
}
