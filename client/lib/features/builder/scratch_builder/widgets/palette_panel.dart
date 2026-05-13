import 'package:flutter/material.dart';

import '../models/block_template.dart';
import 'scratch_block.dart';

class PalettePanel extends StatelessWidget {
  final List<BlockTemplate> templates;

  const PalettePanel({super.key, required this.templates});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 245,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Blocks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          const _CategoryTitle(title: 'Events', color: Color(0xfff6c344)),
          const _CategoryTitle(title: 'Motion', color: Color(0xff4c97ff)),
          const _CategoryTitle(title: 'Looks', color: Color(0xff9966ff)),
          const _CategoryTitle(title: 'Control', color: Color(0xffffab19)),
          const Divider(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: templates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final template = templates[index];

                return Draggable<BlockTemplate>(
                  data: template,
                  feedback: Material(
                    color: Colors.transparent,
                    child: ScratchBlock(template: template),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.35,
                    child: ScratchBlock(template: template),
                  ),
                  child: ScratchBlock(template: template),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _CategoryTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
