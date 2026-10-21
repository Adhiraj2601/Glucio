import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../core/utils/additive_risk_lookup.dart';

/// Neo-Brutalist card displaying detected food additives, E-numbers, and risk levels.
class AdditivesCard extends StatelessWidget {
  final List<String> additiveTags;

  const AdditivesCard({
    super.key,
    this.additiveTags = const [],
  });

  Color _getRiskColor(AdditiveRiskLevel level) {
    switch (level) {
      case AdditiveRiskLevel.low:
        return GlucioTheme.levelLow;
      case AdditiveRiskLevel.moderate:
        return GlucioTheme.levelMedium;
      case AdditiveRiskLevel.high:
        return GlucioTheme.levelHigh;
      case AdditiveRiskLevel.unknown:
        return const Color(0xFF888888);
    }
  }

  String _getRiskLabel(AdditiveRiskLevel level) {
    switch (level) {
      case AdditiveRiskLevel.low:
        return 'Low Risk';
      case AdditiveRiskLevel.moderate:
        return 'Moderate Risk';
      case AdditiveRiskLevel.high:
        return 'High Risk';
      case AdditiveRiskLevel.unknown:
        return 'Unclassified';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (additiveTags.isEmpty) {
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
                'No food additives or E-numbers found in ingredients.',
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

    final additiveInfos = additiveTags.map(AdditiveRiskLookup.lookup).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < additiveInfos.length; i++) ...[
          _buildAdditiveRow(additiveInfos[i]),
          if (i < additiveInfos.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildAdditiveRow(AdditiveInfo info) {
    final riskColor = _getRiskColor(info.riskLevel);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GlucioTheme.cardCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: GlucioTheme.inkBlack,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  info.code,
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontDisplay,
                    fontSize: 11,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.name,
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: riskColor, width: 1.5),
                ),
                child: Text(
                  _getRiskLabel(info.riskLevel),
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            info.function,
            style: const TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          if (info.note != null && info.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              info.note!,
              style: const TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
