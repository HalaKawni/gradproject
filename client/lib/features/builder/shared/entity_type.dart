enum EntityType { playerStart, collectable, goal }

extension EntityTypeExtension on EntityType {
  String get value {
    switch (this) {
      case EntityType.playerStart:
        return 'playerStart';
      case EntityType.collectable:
        return 'collectable';
      case EntityType.goal:
        return 'goal';
    }
  }

  static EntityType fromString(String value) {
    switch (value) {
      case 'playerStart':
        return EntityType.playerStart;
      case 'collectable':
        return EntityType.collectable;
      case 'goal':
      default:
        return EntityType.goal;
    }
  }
}
