import 'package:client/core/localization/app_language.dart';

class TopViewCharacter {
  final String id;
  final String label;
  final String previewAssetPath;
  final String stillAssetPath;
  final String walkSheetAssetPath;

  const TopViewCharacter({
    required this.id,
    required this.label,
    required this.previewAssetPath,
    required this.stillAssetPath,
    required this.walkSheetAssetPath,
  });
}

const String defaultTopViewCharacterId = 'cat';

const List<TopViewCharacter> topViewCharacters = <TopViewCharacter>[
  TopViewCharacter(
    id: 'cat',
    label: 'Cat',
    previewAssetPath:
        'game_builder/character_previews/top_view_character_preview/cat_prv.png',
    stillAssetPath:
        'game_builder/charachters/top_view_character_stills/cat.png',
    walkSheetAssetPath:
        'game_builder/charachters/top_view_characters/cat_walk.png',
  ),
  TopViewCharacter(
    id: 'cow',
    label: 'Cow',
    previewAssetPath:
        'game_builder/character_previews/top_view_character_preview/cow_prv.png',
    stillAssetPath:
        'game_builder/charachters/top_view_character_stills/cow.png',
    walkSheetAssetPath:
        'game_builder/charachters/top_view_characters/cow_walk.png',
  ),
  TopViewCharacter(
    id: 'dog',
    label: 'Dog',
    previewAssetPath:
        'game_builder/character_previews/top_view_character_preview/dog_prv.png',
    stillAssetPath:
        'game_builder/charachters/top_view_character_stills/dog.png',
    walkSheetAssetPath:
        'game_builder/charachters/top_view_characters/dog_walk.png',
  ),
  TopViewCharacter(
    id: 'elephant',
    label: 'Elephant',
    previewAssetPath:
        'game_builder/character_previews/top_view_character_preview/elephant_prv.png',
    stillAssetPath:
        'game_builder/charachters/top_view_character_stills/elephant.png',
    walkSheetAssetPath:
        'game_builder/charachters/top_view_characters/elephant_walk.png',
  ),
  TopViewCharacter(
    id: 'horse',
    label: 'Horse',
    previewAssetPath:
        'game_builder/character_previews/top_view_character_preview/horse_prv.png',
    stillAssetPath:
        'game_builder/charachters/top_view_character_stills/horse.png',
    walkSheetAssetPath:
        'game_builder/charachters/top_view_characters/horse_walk.png',
  ),
];

TopViewCharacter topViewCharacterById(String? id) {
  for (final character in topViewCharacters) {
    if (character.id == id) {
      return character;
    }
  }

  return topViewCharacters.first;
}

String localizedTopViewCharacterLabel(AppLanguage language, String id) {
  final character = topViewCharacterById(id);
  return language.tr('builder.topViewCharacter.$id', character.label);
}
