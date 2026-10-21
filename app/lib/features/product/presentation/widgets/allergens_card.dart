import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';

/// Neo-Brutalist card displaying declared allergens and traces.
class AllergensCard extends StatelessWidget {
  final List<String> allergenTags;
  final List<String> traceTags;

  const AllergensCard({
    super.key,
    this.allergenTags = const [],
    this.traceTags = const [],
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
    final hasAllergens = allergenTags.isNotEmpty;
    final hasTraces = traceTags.isNotEmpty;

    if (!hasAllergens && !hasTraces) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GlucioTheme.cardCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: GlucioTheme.levelLow, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No allergens or traces declared by manufacturer.',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: GlucioTheme.inkBlack,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasAllergens) ...[
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: GlucioTheme.levelHigh, size: 18),
              SizedBox(width: 6),
              Text(
                'CONTAINS ALLERGENS:',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontDisplay,
                  fontSize: 12,
                  color: GlucioTheme.inkBlack,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergenTags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: GlucioTheme.levelHigh.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GlucioTheme.levelHigh, width: 2),
                ),
                child: Text(
                  _cleanTag(tag),
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: GlucioTheme.levelHigh,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (hasAllergens && hasTraces) const SizedBox(height: 14),
        if (hasTraces) ...[
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: GlucioTheme.levelMedium, size: 18),
              SizedBox(width: 6),
              Text(
                'MAY CONTAIN TRACES OF:',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontDisplay,
                  fontSize: 12,
                  color: GlucioTheme.inkBlack,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: traceTags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: GlucioTheme.levelMedium.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                ),
                child: Text(
                  _cleanTag(tag),
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
