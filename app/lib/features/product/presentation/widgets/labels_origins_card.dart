import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';

/// Neo-Brutalist card displaying certifications, labels, and geographical origins.
class LabelsOriginsCard extends StatelessWidget {
  final List<String> labelTags;
  final String? origins;
  final List<String> originTags;

  const LabelsOriginsCard({
    super.key,
    this.labelTags = const [],
    this.origins,
    this.originTags = const [],
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
    final hasLabels = labelTags.isNotEmpty;
    final hasOrigins = (origins != null && origins!.trim().isNotEmpty) ||
        originTags.isNotEmpty;

    if (!hasLabels && !hasOrigins) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GlucioTheme.cardCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
        ),
        child: const Text(
          'No specific certifications or origin labels declared on packaging.',
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
        if (hasLabels) ...[
          const Row(
            children: [
              Icon(Icons.verified_outlined,
                  color: GlucioTheme.inkBlack, size: 18),
              SizedBox(width: 6),
              Text(
                'CERTIFICATIONS & LABELS:',
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
            children: labelTags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: GlucioTheme.accentLime.withValues(alpha: 0.4),
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
        if (hasLabels && hasOrigins) const SizedBox(height: 14),
        if (hasOrigins) ...[
          const Row(
            children: [
              Icon(Icons.public_rounded,
                  color: GlucioTheme.inkBlack, size: 18),
              SizedBox(width: 6),
              Text(
                'ORIGIN & MANUFACTURING:',
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GlucioTheme.cardCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
            ),
            child: Text(
              origins?.trim().isNotEmpty == true
                  ? origins!
                  : originTags.map(_cleanTag).join(', '),
              style: const TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: GlucioTheme.inkBlack,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
