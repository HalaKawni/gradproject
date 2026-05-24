import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';

class BuilderPalette extends StatelessWidget {
  const BuilderPalette({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      color: Colors.grey.shade200,
      child: Center(child: Text(AppLanguage.of(context).t('builder.palette'))),
    );
  }
}
