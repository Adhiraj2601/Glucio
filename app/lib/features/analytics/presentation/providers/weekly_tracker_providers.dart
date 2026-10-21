import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/datasources/local_product_database.dart';
import '../../../../data/models/daily_sugar_summary.dart';
import '../../../../data/models/food_log_entry.dart';
import '../../../log/presentation/providers/daily_tracker_providers.dart';

/// Notifier managing the list of food logs for the past 7 days (including today).
class WeeklyFoodLogsNotifier extends AsyncNotifier<List<FoodLogEntry>> {
  @override
  Future<List<FoodLogEntry>> build() async {
    return _fetchWeeklyLogs();
  }

  Future<List<FoodLogEntry>> _fetchWeeklyLogs() async {
    final db = LocalProductDatabase.instance;
    return await db.getFoodLogsForLastDays(7);
  }

  /// Manually reloads weekly logs from SQLite.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchWeeklyLogs());
  }

  /// Seeds sample logs across the last 6 days for testing/demo.
  Future<void> seedSampleWeek() async {
    final db = LocalProductDatabase.instance;
    await db.seedSampleWeekLogs();
    await reload();
  }

  /// Deletes a specific log entry and refreshes.
  Future<void> deleteLog(int id) async {
    final db = LocalProductDatabase.instance;
    await db.deleteFoodLog(id);
    await reload();
    // Also notify today's notifier to keep them in sync
    ref.invalidate(todayFoodLogsProvider);
  }

  /// Clears all logs in the database.
  Future<void> clearAll() async {
    final db = LocalProductDatabase.instance;
    await db.clearAllFoodLogs();
    await reload();
    ref.invalidate(todayFoodLogsProvider);
  }
}

/// Provider managing food logs for the last 7 days.
final weeklyFoodLogsProvider =
    AsyncNotifierProvider<WeeklyFoodLogsNotifier, List<FoodLogEntry>>(() {
  return WeeklyFoodLogsNotifier();
});

/// Notifier managing the currently selected date on the weekly bar chart (normalized to start of day).
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void select(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

/// The currently selected date on the weekly bar chart.
final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

/// Normalizes a DateTime to year, month, day (midnight local time).
DateTime normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Computes comprehensive 7-day Weekly Analytics based on the user's limit and weekly logs.
final weeklyAnalyticsProvider = Provider<WeeklyAnalytics>((ref) {
  final limitAsync = ref.watch(dailyLimitProvider);
  final limit = limitAsync.value ?? 25.0;
  final weeklyLogsAsync = ref.watch(weeklyFoodLogsProvider);
  final logs = weeklyLogsAsync.value ?? [];

  final now = DateTime.now();
  final todayMidnight = normalizeDate(now);

  // Group logs by day (normalized date -> list of entries)
  final Map<DateTime, List<FoodLogEntry>> grouped = {};
  for (final entry in logs) {
    final dayKey = normalizeDate(entry.loggedAt);
    grouped.putIfAbsent(dayKey, () => []).add(entry);
  }

  // Generate 7 days in chronological order: 6 days ago -> today
  final List<DailySugarSummary> summaries = [];
  for (int i = 6; i >= 0; i--) {
    final dayDate = todayMidnight.subtract(Duration(days: i));
    final dayItems = grouped[dayDate] ?? [];

    double totalSugar = 0.0;
    int unknownCount = 0;

    for (final item in dayItems) {
      if (item.sugarGrams != null) {
        totalSugar += item.sugarGrams!;
      } else {
        unknownCount++;
      }
    }

    summaries.add(
      DailySugarSummary(
        date: dayDate,
        totalSugarGrams: double.parse(totalSugar.toStringAsFixed(1)),
        unknownSugarCount: unknownCount,
        totalItemsCount: dayItems.length,
        targetLimitGrams: limit,
        items: dayItems,
      ),
    );
  }

  return WeeklyAnalytics(
    dailySummaries: summaries,
    dailyTargetGrams: limit,
  );
});

/// Daily summary for the currently selected date.
final selectedDaySummaryProvider = Provider<DailySugarSummary?>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final analytics = ref.watch(weeklyAnalyticsProvider);

  for (final summary in analytics.dailySummaries) {
    if (normalizeDate(summary.date) == normalizeDate(selectedDate)) {
      return summary;
    }
  }
  return null;
});

/// Log items for the currently selected date.
final selectedDayLogsProvider = Provider<List<FoodLogEntry>>((ref) {
  final summary = ref.watch(selectedDaySummaryProvider);
  return summary?.items ?? [];
});

/// Notifier managing full history of all food logs across time.
class AllFoodLogsNotifier extends AsyncNotifier<List<FoodLogEntry>> {
  @override
  Future<List<FoodLogEntry>> build() async {
    return _fetchAllLogs();
  }

  Future<List<FoodLogEntry>> _fetchAllLogs() async {
    final db = LocalProductDatabase.instance;
    return await db.getAllFoodLogs();
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAllLogs());
  }

  Future<void> deleteLog(int id) async {
    final db = LocalProductDatabase.instance;
    await db.deleteFoodLog(id);
    await reload();
    ref.invalidate(weeklyFoodLogsProvider);
    ref.invalidate(todayFoodLogsProvider);
  }
}

/// Provider for complete history of all logs.
final allFoodLogsHistoryProvider =
    AsyncNotifierProvider<AllFoodLogsNotifier, List<FoodLogEntry>>(() {
  return AllFoodLogsNotifier();
});
