import 'package:flutter/material.dart';
import '../../../../core/utils/sugar_calculator.dart';

/// Progress bar widget showing sugar intake relative to the WHO 25g daily limit.
class SugarProgressBar extends StatelessWidget {
  final double sugarGrams;
  final double dailyLimitGrams;

  const SugarProgressBar({
    super.key,
    required this.sugarGrams,
    this.dailyLimitGrams = 25.0,
  });

  @override
  Widget build(BuildContext context) {
    final percent = SugarCalculator.toPercentDailyLimit(
      sugarGrams,
      dailyLimitGrams: dailyLimitGrams,
    );
    final color = SugarCalculator.getSeverityColor(percent);
    final label = SugarCalculator.getSeverityLabel(percent);
    final progressClamped = (percent / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WHO Daily Free Sugar Limit',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressClamped,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percent.toStringAsFixed(0)}% of limit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              Text(
                '${sugarGrams.toStringAsFixed(1)}g / ${dailyLimitGrams.toStringAsFixed(0)}g max',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
            ],
          ),
          if (percent > 100) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ This single item exceeds your entire recommended daily sugar limit by ${(percent - 100).toStringAsFixed(0)}%!',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
