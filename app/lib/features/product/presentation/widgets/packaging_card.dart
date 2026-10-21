import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';

/// Neo-Brutalist card displaying packaging materials, formats, and recycling hints.
class PackagingCard extends StatelessWidget {
  final String? packaging;
  final List<String> packagingTags;

  const PackagingCard({
    super.key,
    this.packaging,
    this.packagingTags = const [],
  });

  String _cleanTag(String tag) {
    var cleaned = tag.trim().toLowerCase();
    if (cleaned.startsWith('en:')) {
      cleaned = cleaned.substring(3);
    }
    cleaned = cleaned.replaceAll('-', ' ');
    if (cleaned.isEmpty) return tag;
    return cleaned
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final hasText = packaging != null && packaging!.trim().isNotEmpty;
    final hasTags = packagingTags.isNotEmpty;

    if (!hasText && !hasTags) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GlucioTheme.cardCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
        ),
        child: const Text(
          'Packaging and recycling information not specified for this item.',
          style: TextStyle(
            fontFamily: GlucioTheme.fontBody,
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasText) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GlucioTheme.cardCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.recycling_rounded,
                    color: GlucioTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    packaging!,
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (hasText && hasTags) const SizedBox(height: 10),
        if (hasTags) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: packagingTags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                ),
                child: Text(
                  _cleanTag(tag),
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
