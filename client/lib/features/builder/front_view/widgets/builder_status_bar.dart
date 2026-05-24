import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';
import '../controllers/builder_controller.dart';
import '../models/level_settings.dart';

class BuilderStatusBar extends StatelessWidget {
  final BuilderController controller;
  final bool showValidation;

  const BuilderStatusBar({
    super.key,
    required this.controller,
    this.showValidation = false,
  });

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    final selectedCell =
        controller.selectedX != null && controller.selectedY != null
        ? '(${controller.selectedX}, ${controller.selectedY})'
        : language.t('builder.none');
    final collectableCount = controller.project.entities
        .where((entity) => entity.type == 'collectable')
        .length;
    final gridPreset = LevelSettings.closestPresetForTileSize(
      controller.project.settings.tileSize,
    );
    final logicStepCount = controller.logicCommandBlockCount;
    final runStatus = controller.isPlaybackRunning
        ? language.t('builder.playing')
        : controller.logicStatusMessage ?? language.t('builder.ready');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(language.t('builder.tool'), controller.currentTool.name),
          _infoRow(language.t('builder.selected'), selectedCell),
          _infoRow(
            language.t('builder.grid'),
            '${controller.project.settings.columns} x ${controller.project.settings.rows}',
          ),
          _infoRow(language.t('builder.sizePreset'), gridPreset.shortLabel),
          _infoRow(
            language.t('builder.tileSize'),
            '${controller.project.settings.tileSize.round()} px',
          ),
          _infoRow(language.t('builder.collectables'), '$collectableCount'),
          _infoRow(language.t('builder.logicBlocks'), '$logicStepCount'),
          _infoRow(language.t('builder.runStatus'), runStatus),
          if (showValidation)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                language.t('builder.draftPublishChecks'),
                style: TextStyle(color: Colors.blueGrey.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
