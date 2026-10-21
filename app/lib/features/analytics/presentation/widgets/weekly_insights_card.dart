import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../providers/weekly_tracker_providers.dart';

/// Neo-Brutalist card displaying 7-day averages, limit compliance, and top sugar sources.
class WeeklyInsightsCard extends ConsumerWidget {
  const WeeklyInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(weeklyAnalyticsProvider);
    final limit = analytics.dailyTargetGrams;
    final avg = analytics.averageDailySugarGrams;
    final avgTsp = analytics.averageDailyTeaspoons;
    final withinCount = analytics.daysWithinLimit;
    final topContributors = analytics.topContributors;
    final unknownCount = analytics.totalUnknownSugarCount;

    final diff = avg - limit;
    final isUnder = diff <= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: GlucioTheme.cardDecoration(
        surface: GlucioTheme.cardCream,
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.insights_rounded, color: GlucioTheme.inkBlack, size: 22),
              SizedBox(width: 8),
              Text(
                'Weekly Insights & Stats',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontDisplay,
                  fontSize: 20,
                  color: GlucioTheme.inkBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Two-column stat boxes
          Row(
            children: [
              // Stat 1: Daily Average
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUnder
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: GlucioTheme.inkBlack,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '7-DAY AVERAGE',
                        style: TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            avg.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: GlucioTheme.fontDisplay,
                              fontSize: 24,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            'g/day',
                            style: TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '≈ ${avgTsp.toStringAsFixed(1)} tsp/day',
                        style: const TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontSize: 10,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isUnder ? GlucioTheme.levelLow : GlucioTheme.levelHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isUnder
                              ? '${(-diff).toStringAsFixed(1)}g below limit'
                              : '+${diff.toStringAsFixed(1)}g above limit',
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
              ),
              const SizedBox(width: 12),

              // Stat 2: Target Adherence
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: withinCount >= 5
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: GlucioTheme.inkBlack,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DAYS WITHIN LIMIT',
                        style: TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$withinCount',
                            style: const TextStyle(
                              fontFamily: GlucioTheme.fontDisplay,
                              fontSize: 24,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            '/ 7 days',
                            style: TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        withinCount == 7
                            ? 'Perfect week!'
                            : (withinCount >= 5 ? 'Great control!' : 'Sugar alert!'),
                        style: const TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: GlucioTheme.inkBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: withinCount >= 5
                              ? GlucioTheme.levelLow
                              : GlucioTheme.levelMedium,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${((withinCount / 7) * 100).toStringAsFixed(0)}% success',
                          style: TextStyle(
                            fontFamily: GlucioTheme.fontBody,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: withinCount >= 5 ? Colors.white : GlucioTheme.inkBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Unknown sugar alert if any item had missing sugar
          if (unknownCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: GlucioTheme.inkBlack),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$unknownCount item${unknownCount == 1 ? '' : 's'} logged this week with unverified sugar data.',
                      style: const TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: GlucioTheme.inkBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Top Sugar Contributors
          if (topContributors.isNotEmpty) ...[
            const Text(
              'Top Sugar Sources This Week:',
              style: TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: GlucioTheme.inkBlack,
              ),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < topContributors.take(3).length; i++)
              _buildContributorTile(topContributors[i], i + 1),
          ],
        ],
      ),
    );
  }

  Widget _buildContributorTile(dynamic contributor, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GlucioTheme.cardCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1
                  ? GlucioTheme.levelHigh
                  : (rank == 2 ? GlucioTheme.levelMedium : GlucioTheme.accentLime),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: GlucioTheme.inkBlack, width: 1),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: GlucioTheme.inkBlack,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contributor.name as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
                Text(
                  '${contributor.brand} • ${contributor.logCount}x logged',
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(contributor.totalSugarGrams as double).toStringAsFixed(1)}g',
            style: const TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: GlucioTheme.levelHigh,
            ),
          ),
        ],
      ),
    );
  }
}
