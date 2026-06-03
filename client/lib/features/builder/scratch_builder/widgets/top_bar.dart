import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';
import '../../shared/widgets/game_builder_back_icon.dart';
import '../../shared/widgets/game_builder_level_title_field.dart';

class TopBar extends StatelessWidget {
  final TextEditingController titleController;
  final VoidCallback onRun;
  final VoidCallback onReset;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;
  final bool isSaving;
  final bool playMode;

  const TopBar({
    super.key,
    required this.titleController,
    required this.onRun,
    required this.onReset,
    required this.onSaveDraft,
    required this.onPublish,
    required this.isSaving,
    required this.playMode,
  });

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const GameBuilderBackIcon(),
          ),
          const SizedBox(width: 12),
          if (playMode)
            Text(
              titleController.text,
              style: Theme.of(context).textTheme.titleLarge,
            )
          else
            GameBuilderLevelTitleField(
              width: 320,
              controller: titleController,
              hintText: language.t('builder.newLevel'),
            ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: isSaving ? null : onReset,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(language.t('builder.reset')),
          ),
          if (!playMode) ...[
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: isSaving ? null : onSaveDraft,
              icon: const Icon(Icons.save_outlined),
              label: Text(language.t('builder.saveDraft')),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: isSaving ? null : onPublish,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(
                isSaving
                    ? language.t('builder.saving')
                    : language.t('builder.publish'),
              ),
            ),
          ],
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: isSaving ? null : onRun,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(language.t('builder.run')),
          ),
        ],
      ),
    );
  }
}
