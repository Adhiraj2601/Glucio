import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../core/utils/sugar_calculator.dart';

/// Progress bar widget showing sugar intake relative to the WHO 25g daily limit.
/// Features Neo-brutalist thick black outlines and hard offset shadows.
class SugarProgressBar extends StatelessWidget {
  final double? sugarGrams;
  final double? sugarPer100;
  final bool isLiquid;
  final double dailyLimitGrams;

  const SugarProgressBar({
    super.key,
    required this.sugarGrams,
    this.sugarPer100,
    this.isLiquid = false,
    this.dailyLimitGrams = 25.0,
  });

  @override
  Widget build(BuildContext context) {
    if (sugarGrams == null) {
      return const SizedBox.shrink();
    }

    final grams = sugarGrams!;
    final percent = SugarCalculator.toPercentDailyLimit(
      grams,
      dailyLimitGrams: dailyLimitGrams,
    )!;
    final trackColor = SugarCalculator.getSeverityColor(percent);

    // Food density badge is calculated on per-100g / per-100ml basis for honesty,
    // preventing small portions of high-sugar foods (like ketchup) from showing a false "Low Sugar" badge.
    final badgeLabel = sugarPer100 != null
        ? SugarCalculator.getFoodSugarDensityLabel(sugarPer100, isLiquid: isLiquid)
        : SugarCalculator.getSeverityLabel(percent);
    final badgeColor = sugarPer100 != null
        ? SugarCalculator.getFoodSugarDensityColor(sugarPer100, isLiquid: isLiquid)
        : trackColor;

    final progressClamped = (percent / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlucioTheme.cardDecoration(
        surface: GlucioTheme.cardCream,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'WHO Daily Limit (25g)',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: GlucioTheme.inkBlack,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                ),
                child: Text(
                  badgeLabel,
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Thick black-outlined progress track with hard shadow
          Container(
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: GlucioTheme.inkBlack, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: GlucioTheme.inkBlack,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: progressClamped,
                    child: Container(
                      decoration: BoxDecoration(
                        color: trackColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percent.toStringAsFixed(0)}% of limit',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontWeight: FontWeight.bold,
                  color: trackColor,
                  fontSize: 13,
                ),
              ),
              Text(
                '${grams.toStringAsFixed(1)}g / ${dailyLimitGrams.toStringAsFixed(0)}g max',
                style: const TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (percent > 100) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ Exceeds entire daily recommended sugar limit by ${(percent - 100).toStringAsFixed(0)}%!',
              style: TextStyle(
                fontFamily: GlucioTheme.fontBody,
                color: trackColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
