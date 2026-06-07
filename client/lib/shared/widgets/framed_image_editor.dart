import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FramedImageEditResult {
  const FramedImageEditResult({
    required this.imageBase64,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  final String? imageBase64;
  final double scale;
  final double offsetX;
  final double offsetY;
}

class FramedImagePreview extends StatelessWidget {
  const FramedImagePreview({
    super.key,
    required this.bytes,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    this.placeholderIcon = Icons.image_outlined,
    this.backgroundColor = const Color(0xFFEFF6F8),
  });

  final Uint8List? bytes;
  final double scale;
  final double offsetX;
  final double offsetY;
  final IconData placeholderIcon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (bytes == null) {
      return ColoredBox(
        color: backgroundColor,
        child: Center(
          child: Icon(
            placeholderIcon,
            size: 38,
            color: Colors.blueGrey.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final frameWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 1.0;
        final frameHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 1.0;

        return ClipRect(
          child: ColoredBox(
            color: backgroundColor,
            child: Transform.translate(
              offset: Offset(
                offsetX * frameWidth * 0.5,
                offsetY * frameHeight * 0.5,
              ),
              child: Transform.scale(
                scale: scale,
                child: Image.memory(
                  bytes!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 38,
                      color: Colors.blueGrey.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<FramedImageEditResult?> showFramedImageUploadDialog({
  required BuildContext context,
  required String title,
  String? initialImageBase64,
  double initialScale = 1,
  double initialOffsetX = 0,
  double initialOffsetY = 0,
  double aspectRatio = 16 / 9,
  bool circularFrame = false,
}) {
  Uint8List? imageBytes = _safeDecodeBase64(initialImageBase64);
  String? imageBase64 = initialImageBase64;
  double scale = initialScale;
  double offsetX = initialOffsetX;
  double offsetY = initialOffsetY;

  Future<Uint8List?> pickImageBytes() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    return result?.files.single.bytes;
  }

  return showDialog<FramedImageEditResult>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FramedImageEditor(
                      bytes: imageBytes,
                      scale: scale,
                      offsetX: offsetX,
                      offsetY: offsetY,
                      aspectRatio: aspectRatio,
                      circularFrame: circularFrame,
                      onOffsetChanged: (offset) {
                        setDialogState(() {
                          offsetX = offset.dx;
                          offsetY = offset.dy;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      imageBytes == null
                          ? 'Choose an image to preview it in the frame.'
                          : circularFrame
                          ? 'Drag or zoom until the photo fits nicely inside the round profile frame.'
                          : 'The whole image is fitted inside the frame. Drag or zoom if you want to adjust it.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blueGrey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final bytes = await pickImageBytes();
                            if (bytes == null) {
                              return;
                            }
                            setDialogState(() {
                              imageBytes = bytes;
                              imageBase64 = base64Encode(bytes);
                              scale = 1;
                              offsetX = 0;
                              offsetY = 0;
                            });
                          },
                          icon: const Icon(Icons.upload_rounded),
                          label: Text(
                            imageBytes == null
                                ? 'Choose image'
                                : 'Replace image',
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (imageBytes != null)
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                imageBytes = null;
                                imageBase64 = null;
                                scale = 1;
                                offsetX = 0;
                                offsetY = 0;
                              });
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Remove'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: scale.clamp(0.5, 3).toDouble(),
                      min: 0.5,
                      max: 3,
                      divisions: 25,
                      label: '${scale.toStringAsFixed(1)}x',
                      onChanged: imageBytes == null
                          ? null
                          : (value) {
                              setDialogState(() => scale = value);
                            },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    FramedImageEditResult(
                      imageBase64: imageBase64,
                      scale: scale,
                      offsetX: offsetX,
                      offsetY: offsetY,
                    ),
                  );
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}

Uint8List? _safeDecodeBase64(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  try {
    return base64Decode(value);
  } catch (_) {
    return null;
  }
}

class FramedImageEditor extends StatelessWidget {
  const FramedImageEditor({
    super.key,
    required this.bytes,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.onOffsetChanged,
    this.aspectRatio = 16 / 9,
    this.maxWidth = 420,
    this.circularFrame = false,
  });

  final Uint8List? bytes;
  final double scale;
  final double offsetX;
  final double offsetY;
  final ValueChanged<Offset> onOffsetChanged;
  final double aspectRatio;
  final double maxWidth;
  final bool circularFrame;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final frameWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : 1.0;
              final frameHeight = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : 1.0;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: bytes == null
                    ? null
                    : (details) {
                        onOffsetChanged(
                          Offset(
                            (offsetX + details.delta.dx / (frameWidth * 0.5))
                                .clamp(-1.0, 1.0)
                                .toDouble(),
                            (offsetY + details.delta.dy / (frameHeight * 0.5))
                                .clamp(-1.0, 1.0)
                                .toDouble(),
                          ),
                        );
                      },
                child: MouseRegion(
                  cursor: bytes == null
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.move,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: circularFrame
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                      borderRadius: circularFrame
                          ? null
                          : BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.shade200),
                    ),
                    child: circularFrame
                        ? ClipOval(
                            child: FramedImagePreview(
                              bytes: bytes,
                              scale: scale,
                              offsetX: offsetX,
                              offsetY: offsetY,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: FramedImagePreview(
                              bytes: bytes,
                              scale: scale,
                              offsetX: offsetX,
                              offsetY: offsetY,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
