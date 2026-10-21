import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/glucio_theme.dart';
import '../../../data/models/food_log_entry.dart';
import 'providers/weekly_tracker_providers.dart';
import 'widgets/weekly_insights_card.dart';
import 'widgets/weekly_sugar_bar_chart.dart';

/// Weekly Trends & Analytics screen showing 7-day sugar patterns and day inspector.
class WeeklyTrendsScreen extends ConsumerWidget {
  const WeeklyTrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyLogsAsync = ref.watch(weeklyFoodLogsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedDaySummary = ref.watch(selectedDaySummaryProvider);
    final selectedDayLogs = ref.watch(selectedDayLogsProvider);

    return Scaffold(
      backgroundColor: GlucioTheme.bgCream,
      body: SafeArea(
        child: weeklyLogsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: GlucioTheme.inkBlack),
          ),
          error: (err, _) => Center(
            child: Text(
              'Error loading analytics: $err',
              style: const TextStyle(fontFamily: GlucioTheme.fontBody),
            ),
          ),
          data: (logs) {
            return RefreshIndicator(
              color: GlucioTheme.inkBlack,
              backgroundColor: GlucioTheme.cardCream,
              onRefresh: () => ref.read(weeklyFoodLogsProvider.notifier).reload(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Screen Title Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weekly Trends',
                                style: TextStyle(
                                  fontFamily: GlucioTheme.fontDisplay,
                                  fontSize: 26,
                                  color: GlucioTheme.inkBlack,
                                ),
                              ),
                              Text(
                                '7-Day Sugar Analytics & Patterns',
                                style: TextStyle(
                                  fontFamily: GlucioTheme.fontBody,
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Refresh button
                        IconButton(
                          icon: const Icon(Icons.refresh, color: GlucioTheme.inkBlack),
                          onPressed: () =>
                              ref.read(weeklyFoodLogsProvider.notifier).reload(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. Neo-Brutalist Weekly Bar Chart
                    const WeeklySugarBarChart(),
                    const SizedBox(height: 18),

                    // 2. Weekly Insights & 7-Day Averages Card
                    const WeeklyInsightsCard(),
                    const SizedBox(height: 18),

                    // 3. Selected Day Inspector Card
                    _buildSelectedDayInspector(
                      context,
                      ref,
                      selectedDate,
                      selectedDaySummary,
                      selectedDayLogs,
                    ),
                    const SizedBox(height: 20),

                    // Debug Quick Tools (Visible only in debug mode)
                    if (kDebugMode) ...[
                      _buildDebugActionButtons(context, ref),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedDayInspector(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    dynamic summary,
    List<FoodLogEntry> items,
  ) {
    final isToday = normalizeDate(selectedDate) == normalizeDate(DateTime.now());
    final dateStr = _formatDateTitle(selectedDate, isToday);

    final totalSugar = summary?.totalSugarGrams ?? 0.0;
    final totalTsp = summary?.totalTeaspoons ?? 0.0;
    final unknownCount = summary?.unknownSugarCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: GlucioTheme.cardDecoration(
        surface: GlucioTheme.cardCream,
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: GlucioTheme.inkBlack, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontDisplay,
                      fontSize: 18,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: GlucioTheme.pillDecoration(
                  fill: summary?.exceedsLimit == true
                      ? GlucioTheme.levelHigh
                      : GlucioTheme.levelLow,
                ),
                child: Text(
                  '${totalSugar.toStringAsFixed(1)}g sugar',
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
          const SizedBox(height: 4),
          Text(
            '${items.length} item${items.length == 1 ? '' : 's'} logged • ≈ ${totalTsp.toStringAsFixed(1)} teaspoons',
            style: const TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          if (unknownCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '⚠ $unknownCount item has missing sugar data.',
              style: const TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: GlucioTheme.inkBlack, thickness: 1.5),
          const SizedBox(height: 8),

          if (items.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(Icons.no_meals_outlined,
                      size: 36, color: Colors.black.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  const Text(
                    'No food items logged for this day.',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            for (final item in items)
              _buildFoodLogItemRow(context, ref, item),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodLogItemRow(
    BuildContext context,
    WidgetRef ref,
    FoodLogEntry item,
  ) {
    final hasSugar = item.sugarGrams != null;
    final timeStr =
        '${item.loggedAt.hour.toString().padLeft(2, '0')}:${item.loggedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GlucioTheme.cardCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: GlucioTheme.inkBlack,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.portionLabel} • $timeStr',
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                if (hasSugar)
                  Text(
                    '${item.sugarGrams!.toStringAsFixed(1)}g sugar (${item.sugarTeaspoonsText})',
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: GlucioTheme.inkBlack,
                    ),
                  )
                else
                  const Text(
                    'Sugar unknown',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: Colors.black54),
            onPressed: () async {
              if (item.id != null) {
                await ref
                    .read(weeklyFoodLogsProvider.notifier)
                    .deleteLog(item.id!);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDebugActionButtons(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'DEBUG TESTING CONTROLS (kDebugMode)',
            style: TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: GlucioTheme.inkBlack,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(weeklyFoodLogsProvider.notifier)
                        .seedSampleWeek();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Seeded 6 days of realistic Indian snack logs!'),
                          backgroundColor: GlucioTheme.primaryGreen,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('Seed Sample Week'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlucioTheme.accentLime,
                    foregroundColor: GlucioTheme.inkBlack,
                    textStyle: const TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(weeklyFoodLogsProvider.notifier).clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All food logs cleared.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.delete_sweep, size: 16),
                label: const Text('Clear All'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  textStyle: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTitle(DateTime dt, bool isToday) {
    if (isToday) return "Today's Logs";
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }
}
