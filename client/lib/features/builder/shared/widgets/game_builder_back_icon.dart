import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GameBuilderBackIcon extends StatelessWidget {
  static const String assetPath = 'assets/game_builder/back.svg';

  final double size;
  final Color? color;

  const GameBuilderBackIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? IconTheme.of(context).color ?? Colors.black,
        BlendMode.srcIn,
      ),
    );
  }
}
