import 'food_log_entry.dart';

/// Aggregated sugar metrics for a single calendar day.
class DailySugarSummary {
  final DateTime date;
  final double totalSugarGrams;
  final int unknownSugarCount;
  final int totalItemsCount;
  final double targetLimitGrams;
  final List<FoodLogEntry> items;

  const DailySugarSummary({
    required this.date,
    required this.totalSugarGrams,
    required this.unknownSugarCount,
    required this.totalItemsCount,
    required this.targetLimitGrams,
    this.items = const [],
  });

  /// True if known sugar exceeds the day's target limit.
  bool get exceedsLimit => totalSugarGrams > targetLimitGrams;

  /// True if at least one logged item had missing/unknown sugar.
  bool get hasUnknownSugar => unknownSugarCount > 0;

  /// Percentage of target limit consumed (0 to 100+).
  double get percentageOfLimit =>
      targetLimitGrams > 0 ? (totalSugarGrams / targetLimitGrams) * 100 : 0.0;

  /// Teaspoons equivalent (1 tsp = 4.0g).
  double get totalTeaspoons => totalSugarGrams / 4.0;
}

/// A product that contributed notably to sugar intake over the week.
class TopSugarContributor {
  final String barcode;
  final String name;
  final String brand;
  final double totalSugarGrams;
  final int logCount;

  const TopSugarContributor({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.totalSugarGrams,
    required this.logCount,
  });
}

/// Comprehensive analytics aggregated over a 7-day period.
class WeeklyAnalytics {
  /// 7 summaries ordered chronologically from oldest (6 days ago) to newest (today).
  final List<DailySugarSummary> dailySummaries;

  /// Daily target limit in grams.
  final double dailyTargetGrams;

  const WeeklyAnalytics({
    required this.dailySummaries,
    required this.dailyTargetGrams,
  });

  /// Total sugar consumed across all 7 days (known sugar only).
  double get totalSugarGrams =>
      dailySummaries.fold(0.0, (sum, d) => sum + d.totalSugarGrams);

  /// 7-day daily average in grams.
  double get averageDailySugarGrams =>
      dailySummaries.isNotEmpty ? totalSugarGrams / dailySummaries.length : 0.0;

  /// 7-day daily average in teaspoons.
  double get averageDailyTeaspoons => averageDailySugarGrams / 4.0;

  /// Count of days where consumed sugar <= target limit.
  int get daysWithinLimit =>
      dailySummaries.where((d) => !d.exceedsLimit).length;

  /// Count of days where consumed sugar > target limit.
  int get daysOverLimit =>
      dailySummaries.where((d) => d.exceedsLimit).length;

  /// Day with the highest sugar intake.
  DailySugarSummary? get highestSugarDay {
    if (dailySummaries.isEmpty) return null;
    DailySugarSummary max = dailySummaries.first;
    for (final d in dailySummaries) {
      if (d.totalSugarGrams > max.totalSugarGrams) {
        max = d;
      }
    }
    return max;
  }

  /// Total count of items logged with missing sugar across the entire week.
  int get totalUnknownSugarCount =>
      dailySummaries.fold(0, (sum, d) => sum + d.unknownSugarCount);

  /// Top sugar contributors sorted by highest sugar first.
  List<TopSugarContributor> get topContributors {
    final Map<String, _ContributorAccumulator> acc = {};

    for (final day in dailySummaries) {
      for (final item in day.items) {
        if (item.sugarGrams == null) continue;
        final key = '${item.barcode}_${item.name}';
        if (!acc.containsKey(key)) {
          acc[key] = _ContributorAccumulator(
            barcode: item.barcode,
            name: item.name,
            brand: item.brand.isNotEmpty ? item.brand : 'Generic',
          );
        }
        acc[key]!.totalSugar += item.sugarGrams!;
        acc[key]!.count += 1;
      }
    }

    final list = acc.values
        .map(
          (a) => TopSugarContributor(
            barcode: a.barcode,
            name: a.name,
            brand: a.brand,
            totalSugarGrams: a.totalSugar,
            logCount: a.count,
          ),
        )
        .toList();

    list.sort((a, b) => b.totalSugarGrams.compareTo(a.totalSugarGrams));
    return list;
  }
}

class _ContributorAccumulator {
  final String barcode;
  final String name;
  final String brand;
  double totalSugar = 0.0;
  int count = 0;

  _ContributorAccumulator({
    required this.barcode,
    required this.name,
    required this.brand,
  });
}
