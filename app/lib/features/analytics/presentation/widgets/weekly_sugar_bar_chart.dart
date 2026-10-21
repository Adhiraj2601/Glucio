import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../data/models/daily_sugar_summary.dart';
import '../providers/weekly_tracker_providers.dart';

/// Interactive Neo-Brutalist 7-day bar chart visualization for sugar intake.
class WeeklySugarBarChart extends ConsumerWidget {
  const WeeklySugarBarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(weeklyAnalyticsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final summaries = analytics.dailySummaries;
    final limit = analytics.dailyTargetGrams;

    // Calculate maximum bar height headroom
    double maxSugar = limit * 1.25; // Guarantee target line is visible with headroom
    for (final s in summaries) {
      if (s.totalSugarGrams > maxSugar) {
        maxSugar = s.totalSugarGrams * 1.15;
      }
    }
    if (maxSugar <= 0) maxSugar = 30.0;

    const double chartPlotHeight = 180.0;
    final double targetLineFraction = (limit / maxSugar).clamp(0.0, 1.0);
    final double targetLineBottom = chartPlotHeight * targetLineFraction;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: GlucioTheme.cardDecoration(
        surface: GlucioTheme.cardCream,
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, color: GlucioTheme.inkBlack, size: 22),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Weekly Sugar',
                        style: TextStyle(
                          fontFamily: GlucioTheme.fontDisplay,
                          fontSize: 19,
                          color: GlucioTheme.inkBlack,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: GlucioTheme.pillDecoration(fill: GlucioTheme.cardCream),
                child: Text(
                  'Target: ${limit.toStringAsFixed(0)}g',
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Daily totals vs target. Tap any bar to inspect food logs.',
            style: TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 18),

          // Bar Chart Area with Target Guideline
          SizedBox(
            height: chartPlotHeight + 52, // Plot + day label area
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Horizontal Target Guideline Line
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: targetLineBottom + 52,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 2,
                          color: GlucioTheme.inkBlack.withValues(alpha: 0.35),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: GlucioTheme.inkBlack,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${limit.toStringAsFixed(0)}g LIMIT',
                          style: const TextStyle(
                            fontFamily: GlucioTheme.fontBody,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 7 Vertical Daily Columns
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < summaries.length; i++)
                        Expanded(
                          child: _buildDayColumn(
                            context: context,
                            ref: ref,
                            summary: summaries[i],
                            isSelected: normalizeDate(summaries[i].date) ==
                                normalizeDate(selectedDate),
                            maxSugar: maxSugar,
                            plotHeight: chartPlotHeight,
                            isToday: i == summaries.length - 1,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayColumn({
    required BuildContext context,
    required WidgetRef ref,
    required DailySugarSummary summary,
    required bool isSelected,
    required double maxSugar,
    required double plotHeight,
    required bool isToday,
  }) {
    final double fillFraction = (summary.totalSugarGrams / maxSugar).clamp(0.0, 1.0);
    final double barHeight = math.max(6.0, plotHeight * fillFraction);

    // Color based on threshold
    Color barColor;
    if (summary.totalSugarGrams == 0.0) {
      barColor = Colors.black12;
    } else if (summary.percentageOfLimit <= 50) {
      barColor = GlucioTheme.levelLow;
    } else if (summary.percentageOfLimit <= 100) {
      barColor = GlucioTheme.levelMedium;
    } else {
      barColor = GlucioTheme.levelHigh;
    }

    final dayName = _formatDayName(summary.date, isToday);
    final dayNum = '${summary.date.day}';

    return GestureDetector(
      onTap: () {
        ref.read(selectedDateProvider.notifier).select(summary.date);
      },
      child: Container(
        color: Colors.transparent, // expand hit test
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Sugar amount label & unknown warning icon
            SizedBox(
              height: 24,
              child: summary.totalItemsCount > 0
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          summary.totalSugarGrams > 0
                              ? '${summary.totalSugarGrams.toStringAsFixed(0)}g'
                              : '0g',
                          style: TextStyle(
                            fontFamily: GlucioTheme.fontBody,
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? GlucioTheme.inkBlack : Colors.black87,
                          ),
                        ),
                        if (summary.hasUnknownSugar) ...[
                          const SizedBox(width: 1),
                          const Icon(
                            Icons.help_outline,
                            size: 10,
                            color: Colors.orange,
                          ),
                        ],
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 2),

            // Bar Container
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isSelected ? 28 : 22,
              height: barHeight,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                border: Border.all(
                  color: GlucioTheme.inkBlack,
                  width: isSelected ? 2.5 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: GlucioTheme.inkBlack,
                    offset: isSelected ? const Offset(2.5, 2.5) : const Offset(1.5, 1.5),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Day Pill (Highlighted when selected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? GlucioTheme.accentLime : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: GlucioTheme.inkBlack, width: 2.0)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isToday ? 'Today' : dayName,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: isToday ? 8.5 : 10,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? GlucioTheme.inkBlack : (isToday ? Colors.black : Colors.black54),
                    ),
                  ),
                  Text(
                    dayNum,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 9,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? GlucioTheme.inkBlack : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDayName(DateTime dt, bool isToday) {
    if (isToday) return 'Today';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[dt.weekday - 1];
  }
}
