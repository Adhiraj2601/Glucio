import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/datasources/local_product_database.dart';
import '../../../../data/models/food_log_entry.dart';

/// Notifier managing the user's daily sugar limit setting (defaults to 25.0g WHO guideline).
class DailyLimitNotifier extends AsyncNotifier<double> {
  @override
  Future<double> build() async {
    return await LocalProductDatabase.instance.getDailyLimit();
  }

  Future<void> updateLimit(double newLimit) async {
    if (newLimit <= 0) return;
    await LocalProductDatabase.instance.setDailyLimit(newLimit);
    state = AsyncData(newLimit);
  }
}

/// Provider for the user's daily sugar limit.
final dailyLimitProvider =
    AsyncNotifierProvider<DailyLimitNotifier, double>(DailyLimitNotifier.new);

/// Notifier managing the list of food entries logged for today.
class TodayFoodLogsNotifier extends AsyncNotifier<List<FoodLogEntry>> {
  @override
  Future<List<FoodLogEntry>> build() async {
    return await LocalProductDatabase.instance.getFoodLogsForDate();
  }

  /// Adds a new food log entry, persists to SQLite, and updates state.
  Future<void> addLog(FoodLogEntry entry) async {
    await LocalProductDatabase.instance.insertFoodLog(entry);
    state = await AsyncValue.guard(
      () => LocalProductDatabase.instance.getFoodLogsForDate(),
    );
  }

  /// Deletes a food log entry by its primary key ID and updates state.
  Future<void> deleteLog(int id) async {
    await LocalProductDatabase.instance.deleteFoodLog(id);
    state = await AsyncValue.guard(
      () => LocalProductDatabase.instance.getFoodLogsForDate(),
    );
  }

  /// Clears all food logs for today.
  Future<void> clearToday() async {
    await LocalProductDatabase.instance.clearFoodLogsForDate();
    state = await AsyncValue.guard(
      () => LocalProductDatabase.instance.getFoodLogsForDate(),
    );
  }

  /// Reloads today's food logs from database.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => LocalProductDatabase.instance.getFoodLogsForDate(),
    );
  }
}

/// Provider for today's food log entries.
final todayFoodLogsProvider =
    AsyncNotifierProvider<TodayFoodLogsNotifier, List<FoodLogEntry>>(
  TodayFoodLogsNotifier.new,
);

/// Derived provider summing total grams of sugar logged today (ignoring null/missing items).
final todayTotalSugarProvider = Provider<double>((ref) {
  final logsAsync = ref.watch(todayFoodLogsProvider);
  return logsAsync.maybeWhen(
    data: (logs) => logs.fold(
      0.0,
      (sum, entry) => sum + (entry.sugarGrams ?? 0.0),
    ),
    orElse: () => 0.0,
  );
});

/// Derived provider counting how many logged items today have missing/unknown sugar data.
final todayUnknownSugarCountProvider = Provider<int>((ref) {
  final logsAsync = ref.watch(todayFoodLogsProvider);
  return logsAsync.maybeWhen(
    data: (logs) => logs.where((e) => e.sugarGrams == null).length,
    orElse: () => 0,
  );
});

/// Derived provider converting total sugar grams to teaspoons (1 tsp = 4.0g).
final todayTotalTeaspoonsProvider = Provider<double>((ref) {
  final grams = ref.watch(todayTotalSugarProvider);
  return grams / 4.0;
});
