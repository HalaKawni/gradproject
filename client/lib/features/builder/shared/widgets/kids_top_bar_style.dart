import 'package:flutter/material.dart';

class KidsTopBarStyle {
  static const Color background = Color(0xFFFFFBEB);
  static const Color ink = Color(0xFF243B53);
  static const Color blue = Color(0xFF2F80ED);
  static const Color green = Color(0xFF39B54A);
  static const Color orange = Color(0xFFFF9F1C);
  static const Color pink = Color(0xFFFF5C8A);

  static const TextStyle titleTextStyle = TextStyle(
    color: ink,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );

  static const double toolbarHeight = 72;

  static PreferredSizeWidget appBarBottom() {
    return const PreferredSize(
      preferredSize: Size.fromHeight(5),
      child: _ColorStripe(),
    );
  }

  static BoxDecoration topBarDecoration() {
    return BoxDecoration(
      color: background,
      boxShadow: [
        BoxShadow(
          color: orange.withValues(alpha: 0.18),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  static ButtonStyle playfulOutlined(Color color) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      backgroundColor: Colors.white,
      side: BorderSide(color: color.withValues(alpha: 0.62), width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900),
    );
  }

  static ButtonStyle playfulFilled(Color color) {
    return FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.blueGrey.shade100,
      disabledForegroundColor: Colors.blueGrey.shade400,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900),
    );
  }

  static ButtonStyle playfulText(Color color) {
    return TextButton.styleFrom(
      foregroundColor: color,
      backgroundColor: color.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900),
    );
  }
}

class _ColorStripe extends StatelessWidget {
  const _ColorStripe();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: ColoredBox(color: KidsTopBarStyle.blue)),
        Expanded(child: ColoredBox(color: KidsTopBarStyle.green)),
        Expanded(child: ColoredBox(color: KidsTopBarStyle.orange)),
        Expanded(child: ColoredBox(color: KidsTopBarStyle.pink)),
      ],
    );
  }
}
