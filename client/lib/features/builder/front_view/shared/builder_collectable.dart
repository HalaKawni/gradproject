import 'package:client/core/localization/app_language.dart';

class BuilderCollectable {
  final String id;
  final String label;
  final String fileName;

  const BuilderCollectable({
    required this.id,
    required this.label,
    required this.fileName,
  });

  String get assetPath => 'game_builder/collectables/$fileName';
  String get flutterAssetPath => assetPath;
}

const String defaultBuilderCollectableId = 'banana';

const List<BuilderCollectable> builderCollectables = <BuilderCollectable>[
  BuilderCollectable(id: 'banana', label: 'Banana', fileName: 'banana.png'),
  BuilderCollectable(
    id: 'black-berry-dark',
    label: 'Black Berry Dark',
    fileName: 'black-berry-dark.png',
  ),
  BuilderCollectable(
    id: 'black-berry-light',
    label: 'Black Berry Light',
    fileName: 'black-berry-light.png',
  ),
  BuilderCollectable(
    id: 'black-cherry',
    label: 'Black Cherry',
    fileName: 'black-cherry.png',
  ),
  BuilderCollectable(id: 'coconut', label: 'Coconut', fileName: 'coconut.png'),
  BuilderCollectable(
    id: 'green-apple',
    label: 'Green Apple',
    fileName: 'green-apple.png',
  ),
  BuilderCollectable(
    id: 'green-grape',
    label: 'Green Grape',
    fileName: 'green-grape.png',
  ),
  BuilderCollectable(id: 'lemon', label: 'Lemon', fileName: 'lemon.png'),
  BuilderCollectable(id: 'lime', label: 'Lime', fileName: 'lime.png'),
  BuilderCollectable(id: 'orange', label: 'Orange', fileName: 'orange.png'),
  BuilderCollectable(id: 'peach', label: 'Peach', fileName: 'peach.png'),
  BuilderCollectable(id: 'pear', label: 'Pear', fileName: 'pear.png'),
  BuilderCollectable(id: 'plum', label: 'Plum', fileName: 'plum.png'),
  BuilderCollectable(
    id: 'raspberry',
    label: 'Raspberry',
    fileName: 'raspberry.png',
  ),
  BuilderCollectable(
    id: 'red-apple',
    label: 'Red Apple',
    fileName: 'red-apple.png',
  ),
  BuilderCollectable(
    id: 'red-cherry',
    label: 'Red Cherry',
    fileName: 'red-cherry.png',
  ),
  BuilderCollectable(
    id: 'red-grape',
    label: 'Red Grape',
    fileName: 'red-grape.png',
  ),
  BuilderCollectable(
    id: 'star-fruit',
    label: 'Star Fruit',
    fileName: 'star-fruit.png',
  ),
  BuilderCollectable(
    id: 'strawberry',
    label: 'Strawberry',
    fileName: 'strawberry.png',
  ),
  BuilderCollectable(
    id: 'watermelon',
    label: 'Watermelon',
    fileName: 'watermelon.png',
  ),
];

BuilderCollectable builderCollectableById(String? id) {
  for (final collectable in builderCollectables) {
    if (collectable.id == id) {
      return collectable;
    }
  }

  return builderCollectables.first;
}

String localizedBuilderCollectableLabel(AppLanguage language, String id) {
  final collectable = builderCollectableById(id);
  return language.tr('builder.collectable.$id', collectable.label);
}
