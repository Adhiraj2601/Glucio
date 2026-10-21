import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/glucio_theme.dart';
import '../../../data/models/food_log_entry.dart';
import '../../analytics/presentation/providers/weekly_tracker_providers.dart';

/// Full history timeline screen showing all logged food items grouped chronologically by date.
class FoodHistoryScreen extends ConsumerWidget {
  const FoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(allFoodLogsHistoryProvider);

    return Scaffold(
      backgroundColor: GlucioTheme.bgCream,
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: GlucioTheme.inkBlack),
          ),
          error: (err, _) => Center(
            child: Text(
              'Error loading history: $err',
              style: const TextStyle(fontFamily: GlucioTheme.fontBody),
            ),
          ),
          data: (logs) {
            final grouped = _groupLogsByDate(logs);

            return RefreshIndicator(
              color: GlucioTheme.inkBlack,
              backgroundColor: GlucioTheme.cardCream,
              onRefresh: () =>
                  ref.read(allFoodLogsHistoryProvider.notifier).reload(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Food History',
                                style: TextStyle(
                                  fontFamily: GlucioTheme.fontDisplay,
                                  fontSize: 26,
                                  color: GlucioTheme.inkBlack,
                                ),
                              ),
                              Text(
                                'Timeline of all your logged snacks & drinks',
                                style: TextStyle(
                                  fontFamily: GlucioTheme.fontBody,
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: GlucioTheme.inkBlack),
                          onPressed: () =>
                              ref.read(allFoodLogsHistoryProvider.notifier).reload(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (logs.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: GlucioTheme.cardDecoration(
                          surface: GlucioTheme.cardCream,
                          radius: 20,
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 48,
                              color: Colors.black38,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No food logged yet',
                              style: TextStyle(
                                fontFamily: GlucioTheme.fontDisplay,
                                fontSize: 18,
                                color: GlucioTheme.inkBlack,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Scan snacks or beverages on the home tab to build your sugar log timeline.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: GlucioTheme.fontBody,
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            if (kDebugMode) ...[
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await ref
                                      .read(weeklyFoodLogsProvider.notifier)
                                      .seedSampleWeek();
                                  await ref
                                      .read(allFoodLogsHistoryProvider.notifier)
                                      .reload();
                                },
                                icon: const Icon(Icons.auto_fix_high, size: 16),
                                label: const Text('Seed Sample Week Data'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GlucioTheme.accentLime,
                                  foregroundColor: GlucioTheme.inkBlack,
                                  textStyle: const TextStyle(
                                    fontFamily: GlucioTheme.fontBody,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      // Chronological list of date groups
                      for (final entry in grouped.entries)
                        _buildDateGroup(context, ref, entry.key, entry.value),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Map<DateTime, List<FoodLogEntry>> _groupLogsByDate(List<FoodLogEntry> logs) {
    final Map<DateTime, List<FoodLogEntry>> map = {};
    for (final l in logs) {
      final dateKey = DateTime(l.loggedAt.year, l.loggedAt.month, l.loggedAt.day);
      map.putIfAbsent(dateKey, () => []).add(l);
    }
    return map;
  }

  Widget _buildDateGroup(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    List<FoodLogEntry> items,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String title;
    if (date == today) {
      title = 'Today';
    } else if (date == yesterday) {
      title = 'Yesterday';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      title = '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

    double daySugar = 0.0;
    int unknownCount = 0;
    for (final it in items) {
      if (it.sugarGrams != null) {
        daySugar += it.sugarGrams!;
      } else {
        unknownCount++;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: GlucioTheme.cardDecoration(
        surface: GlucioTheme.cardCream,
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: GlucioTheme.fontDisplay,
                  fontSize: 18,
                  color: GlucioTheme.inkBlack,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: GlucioTheme.pillDecoration(
                  fill: GlucioTheme.accentLime.withValues(alpha: 0.35),
                ),
                child: Text(
                  '${daySugar.toStringAsFixed(1)}g total',
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
          if (unknownCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '⚠ $unknownCount item with missing sugar data',
              style: const TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 10,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(color: GlucioTheme.inkBlack, thickness: 1.5),
          const SizedBox(height: 8),

          for (final item in items)
            _buildHistoryItemRow(context, ref, item),
        ],
      ),
    );
  }

  Widget _buildHistoryItemRow(
    BuildContext context,
    WidgetRef ref,
    FoodLogEntry item,
  ) {
    final hasSugar = item.sugarGrams != null;
    final timeStr =
        '${item.loggedAt.hour.toString().padLeft(2, '0')}:${item.loggedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GlucioTheme.cardCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GlucioTheme.inkBlack, width: 1.2),
      ),
      child: Row(
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
                    fontSize: 12,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
                Text(
                  '${item.portionLabel} • $timeStr',
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
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
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.black45),
            onPressed: () async {
              if (item.id != null) {
                await ref
                    .read(allFoodLogsHistoryProvider.notifier)
                    .deleteLog(item.id!);
              }
            },
          ),
        ],
      ),
    );
  }
}
