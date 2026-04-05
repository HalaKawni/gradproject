import 'package:flutter/material.dart';

class BuilderPalette extends StatelessWidget {
  const BuilderPalette({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      color: Colors.grey.shade200,
      child: const Center(
        child: Text('Palette'),
      ),
    );
  }
}