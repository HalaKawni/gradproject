import 'dart:convert';
import 'dart:typed_data';

enum CustomAssetType { character, obstacle, collectable, goal, background }

extension CustomAssetTypeExtension on CustomAssetType {
  String get value {
    switch (this) {
      case CustomAssetType.character:
        return 'character';
      case CustomAssetType.obstacle:
        return 'obstacle';
      case CustomAssetType.collectable:
        return 'collectable';
      case CustomAssetType.goal:
        return 'goal';
      case CustomAssetType.background:
        return 'background';
    }
  }

  String get label {
    switch (this) {
      case CustomAssetType.character:
        return 'Character';
      case CustomAssetType.obstacle:
        return 'Obstacle';
      case CustomAssetType.collectable:
        return 'Collectable';
      case CustomAssetType.goal:
        return 'Goal';
      case CustomAssetType.background:
        return 'Background';
    }
  }

  static CustomAssetType fromString(String? value) {
    switch (value) {
      case 'character':
        return CustomAssetType.character;
      case 'obstacle':
        return CustomAssetType.obstacle;
      case 'collectable':
        return CustomAssetType.collectable;
      case 'goal':
        return CustomAssetType.goal;
      case 'background':
        return CustomAssetType.background;
      case 'decoration':
        return CustomAssetType.obstacle;
      default:
        return CustomAssetType.obstacle;
    }
  }
}

class CustomAssetData {
  final String id;
  final String? assetId;
  final String name;
  final CustomAssetType type;
  final String imageBase64;
  final String mimeType;
  final bool isCreatedByUser;
  final bool isPublic;
  final double frameScale;
  final double frameOffsetX;
  final double frameOffsetY;

  const CustomAssetData({
    required this.id,
    this.assetId,
    required this.name,
    required this.type,
    this.imageBase64 = '',
    required this.mimeType,
    this.isCreatedByUser = true,
    this.isPublic = false,
    this.frameScale = 1,
    this.frameOffsetX = 0,
    this.frameOffsetY = 0,
  });

  Uint8List get imageBytes => base64Decode(imageBase64);
  bool get hasEmbeddedImage => imageBase64.isNotEmpty;
  bool get hasUploadedAsset => assetId != null && assetId!.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (hasUploadedAsset) 'assetId': assetId,
      'name': name,
      'type': type.value,
      if (imageBase64.isNotEmpty) 'imageBase64': imageBase64,
      'mimeType': mimeType,
      'isCreatedByUser': isCreatedByUser,
      'isPublic': isPublic,
      'frameScale': frameScale,
      'frameOffsetX': frameOffsetX,
      'frameOffsetY': frameOffsetY,
    };
  }

  factory CustomAssetData.fromJson(Map<String, dynamic> json) {
    return CustomAssetData(
      id: json['id']?.toString() ?? '',
      assetId: json['assetId']?.toString(),
      name: json['name']?.toString() ?? 'Untitled asset',
      type: CustomAssetTypeExtension.fromString(json['type']?.toString()),
      imageBase64: json['imageBase64']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? 'image/png',
      isCreatedByUser: json['isCreatedByUser'] != false,
      isPublic: json['isPublic'] == true,
      frameScale: _readDouble(json['frameScale'], fallback: 1),
      frameOffsetX: _readDouble(json['frameOffsetX']),
      frameOffsetY: _readDouble(json['frameOffsetY']),
    );
  }

  CustomAssetData copyWith({
    String? id,
    String? assetId,
    String? name,
    CustomAssetType? type,
    String? imageBase64,
    String? mimeType,
    bool? isCreatedByUser,
    bool? isPublic,
    double? frameScale,
    double? frameOffsetX,
    double? frameOffsetY,
  }) {
    return CustomAssetData(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      name: name ?? this.name,
      type: type ?? this.type,
      imageBase64: imageBase64 ?? this.imageBase64,
      mimeType: mimeType ?? this.mimeType,
      isCreatedByUser: isCreatedByUser ?? this.isCreatedByUser,
      isPublic: isPublic ?? this.isPublic,
      frameScale: frameScale ?? this.frameScale,
      frameOffsetX: frameOffsetX ?? this.frameOffsetX,
      frameOffsetY: frameOffsetY ?? this.frameOffsetY,
    );
  }
}

double _readDouble(Object? value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
