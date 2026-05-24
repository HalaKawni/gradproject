import 'package:client/core/localization/app_language.dart';

class TopViewBackground {
  final String id;
  final String label;
  final String assetPath;

  const TopViewBackground({
    required this.id,
    required this.label,
    required this.assetPath,
  });
}

class TopViewObstacleStyle {
  final String id;
  final String label;
  final String assetPath;

  const TopViewObstacleStyle({
    required this.id,
    required this.label,
    required this.assetPath,
  });
}

const String defaultTopViewBackgroundId = 'grass';
const String defaultTopViewObstacleStyleId = 'bush1';

const List<TopViewBackground> topViewBackgrounds = <TopViewBackground>[
  TopViewBackground(
    id: 'grass',
    label: 'Grass',
    assetPath: 'game_builder/background/grassTopDown.png',
  ),
  TopViewBackground(
    id: 'sand',
    label: 'Sand',
    assetPath: 'game_builder/background/sandTopDown.png',
  ),
];

const List<TopViewObstacleStyle> topViewObstacleStyles = <TopViewObstacleStyle>[
  TopViewObstacleStyle(
    id: 'bush1',
    label: 'Bush 1',
    assetPath: 'game_builder/top_down_obstacles/bush1.png',
  ),
  TopViewObstacleStyle(
    id: 'bush2',
    label: 'Bush 2',
    assetPath: 'game_builder/top_down_obstacles/bush2.png',
  ),
  TopViewObstacleStyle(
    id: 'bush3',
    label: 'Bush 3',
    assetPath: 'game_builder/top_down_obstacles/bush3.png',
  ),
  TopViewObstacleStyle(
    id: 'bush4',
    label: 'Bush 4',
    assetPath: 'game_builder/top_down_obstacles/bush4.png',
  ),
  TopViewObstacleStyle(
    id: 'bush5',
    label: 'Bush 5',
    assetPath: 'game_builder/top_down_obstacles/bush5.png',
  ),
  TopViewObstacleStyle(
    id: 'cactus1',
    label: 'Cactus 1',
    assetPath: 'game_builder/top_down_obstacles/cactus1.png',
  ),
  TopViewObstacleStyle(
    id: 'cactus2',
    label: 'Cactus 2',
    assetPath: 'game_builder/top_down_obstacles/cactus2.png',
  ),
  TopViewObstacleStyle(
    id: 'log1',
    label: 'Log 1',
    assetPath: 'game_builder/top_down_obstacles/log1.png',
  ),
  TopViewObstacleStyle(
    id: 'log2',
    label: 'Log 2',
    assetPath: 'game_builder/top_down_obstacles/log2.png',
  ),
  TopViewObstacleStyle(
    id: 'log3',
    label: 'Log 3',
    assetPath: 'game_builder/top_down_obstacles/log3.png',
  ),
  TopViewObstacleStyle(
    id: 'rock1',
    label: 'Rock 1',
    assetPath: 'game_builder/top_down_obstacles/rock1.png',
  ),
  TopViewObstacleStyle(
    id: 'rock2',
    label: 'Rock 2',
    assetPath: 'game_builder/top_down_obstacles/rock2.png',
  ),
];

TopViewBackground topViewBackgroundById(String? id) {
  for (final background in topViewBackgrounds) {
    if (background.id == id) {
      return background;
    }
  }

  return topViewBackgrounds.first;
}

TopViewObstacleStyle topViewObstacleStyleById(String? id) {
  for (final obstacle in topViewObstacleStyles) {
    if (obstacle.id == id) {
      return obstacle;
    }
  }

  return topViewObstacleStyles.first;
}

String localizedTopViewBackgroundLabel(AppLanguage language, String id) {
  final background = topViewBackgroundById(id);
  return language.tr('builder.topViewBackground.$id', background.label);
}

String localizedTopViewObstacleLabel(AppLanguage language, String id) {
  final obstacle = topViewObstacleStyleById(id);
  return language.tr('builder.topViewObstacle.$id', obstacle.label);
}
