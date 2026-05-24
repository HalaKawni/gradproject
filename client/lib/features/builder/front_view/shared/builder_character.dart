import 'package:client/core/localization/app_language.dart';

class BuilderCharacterSpriteRect {
  final double? maxWidthScale;
  final double? maxHeightScale;
  final double? facingLeftOffsetXScale;
  final double? facingRightOffsetXScale;
  final double? offsetYScale;

  const BuilderCharacterSpriteRect({
    this.maxWidthScale,
    this.maxHeightScale,
    this.facingLeftOffsetXScale,
    this.facingRightOffsetXScale,
    this.offsetYScale,
  });
}

class BuilderCharacter {
  final String id;
  final String label;
  final String filePrefix;
  final String walkFolder;
  final double sourceInsetLeft;
  final double sourceInsetTop;
  final double sourceInsetRight;
  final double sourceInsetBottom;
  final BuilderCharacterSpriteRect spriteRect;

  const BuilderCharacter({
    required this.id,
    required this.label,
    required this.filePrefix,
    this.walkFolder = '03-Walk/01-Walk',
    this.sourceInsetLeft = 0,
    this.sourceInsetTop = 0,
    this.sourceInsetRight = 0,
    this.sourceInsetBottom = 0,
    this.spriteRect = const BuilderCharacterSpriteRect(),
  });

  String get basePath => 'game_builder/charachters/$id';
  String get idlePreviewAssetPath => 'game_builder/character_previews/$id.png';
}

const String defaultBuilderCharacterId = 'polar';

const List<BuilderCharacter> builderCharacters = <BuilderCharacter>[
  BuilderCharacter(id: 'polar', label: 'Polar', filePrefix: 'FA_PANDA'),
  BuilderCharacter(
    id: 'chicken',
    label: 'Chicken',
    filePrefix: 'FA_CHICKEN',
    walkFolder: '03-Walk',
  ),
  BuilderCharacter(
    id: 'duck',
    label: 'Duck',
    filePrefix: 'FA_DUCKY',
    walkFolder: '03-Walk',
  ),
  BuilderCharacter(
    id: 'penguin',
    label: 'Penguin',
    filePrefix: 'FA_PENGUIN',
    walkFolder: '03-Walk',
  ),
  BuilderCharacter(
    id: 'reindeer',
    label: 'Reindeer',
    filePrefix: 'NUDE_REINDEER',
    spriteRect: BuilderCharacterSpriteRect(
      maxWidthScale: 1.5,
      maxHeightScale: 1.8,
      facingLeftOffsetXScale: 0.15,
      facingRightOffsetXScale: -0.05,
      offsetYScale: 0.33,
    ),
  ),
  BuilderCharacter(id: 'teddy', label: 'Teddy', filePrefix: 'FA_TEDDY'),
];

BuilderCharacter builderCharacterById(String? id) {
  for (final character in builderCharacters) {
    if (character.id == id) {
      return character;
    }
  }

  return builderCharacters.first;
}

String localizedBuilderCharacterLabel(AppLanguage language, String id) {
  final character = builderCharacterById(id);
  return language.tr('builder.character.$id', character.label);
}
