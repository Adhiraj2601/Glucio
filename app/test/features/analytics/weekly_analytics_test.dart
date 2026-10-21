import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/data/models/daily_sugar_summary.dart';
import 'package:glucio/data/models/food_log_entry.dart';

void main() {
  group('WeeklyAnalytics Domain & Aggregation Tests', () {
    final now = DateTime(2026, 10, 21, 12, 0);

    test('computes total sugar, 7-day average grams, and teaspoons accurately', () {
      final days = [
        DailySugarSummary(
          date: now.subtract(const Duration(days: 6)),
          totalSugarGrams: 10.0,
          unknownSugarCount: 0,
          totalItemsCount: 1,
          targetLimitGrams: 25.0,
        ),
        DailySugarSummary(
          date: now.subtract(const Duration(days: 5)),
          totalSugarGrams: 20.0,
          unknownSugarCount: 0,
          totalItemsCount: 2,
          targetLimitGrams: 25.0,
        ),
        DailySugarSummary(
          date: now.subtract(const Duration(days: 4)),
          totalSugarGrams: 30.0, // Exceeds limit
          unknownSugarCount: 0,
          totalItemsCount: 2,
          targetLimitGrams: 25.0,
        ),
        DailySugarSummary(
          date: now.subtract(const Duration(days: 3)),
          totalSugarGrams: 0.0,
          unknownSugarCount: 1, // Unknown sugar item
          totalItemsCount: 1,
          targetLimitGrams: 25.0,
        ),
        DailySugarSummary(
          date: now.subtract(const Duration(days: 2)),
          totalSugarGrams: 15.0,
          unknownSugarCount: 0,
          totalItemsCount: 1,
          targetLimitGrams: 25.0,
        ),
        DailySugarSummary(
          date: now.subtract(const Duration(days: 1)),
          totalSugarGrams: 25.0, // Exactly at limit
          unknownSugarCount: 0,
          totalItemsCount: 2,
          targetLimitGrams: 25.0,
        ),
        DailySugarSummary(
          date: now,
          totalSugarGrams: 40.0, // Exceeds limit
          unknownSugarCount: 0,
          totalItemsCount: 3,
          targetLimitGrams: 25.0,
        ),
      ];

      final analytics = WeeklyAnalytics(
        dailySummaries: days,
        dailyTargetGrams: 25.0,
      );

      // Total = 10 + 20 + 30 + 0 + 15 + 25 + 40 = 140g
      expect(analytics.totalSugarGrams, 140.0);

      // Average = 140 / 7 = 20.0g / day
      expect(analytics.averageDailySugarGrams, 20.0);

      // Average teaspoons = 20.0 / 4.0 = 5.0 tsp
      expect(analytics.averageDailyTeaspoons, 5.0);

      // Days within limit (<= 25g): Days with 10, 20, 0, 15, 25 -> 5 days
      expect(analytics.daysWithinLimit, 5);

      // Days over limit (> 25g): Days with 30, 40 -> 2 days
      expect(analytics.daysOverLimit, 2);

      // Highest sugar day: today (40.0g)
      expect(analytics.highestSugarDay?.totalSugarGrams, 40.0);
      expect(analytics.highestSugarDay?.date, now);

      // Total unknown sugar count: 1
      expect(analytics.totalUnknownSugarCount, 1);
    });

    test('aggregates top sugar contributors correctly across days', () {
      final item1 = FoodLogEntry(
        barcode: '8901764012211',
        name: 'Thums Up',
        brand: 'Coca-Cola',
        portionLabel: 'Whole pack',
        portionAmount: 300.0,
        portionBasis: 'ml',
        sugarGrams: 31.8,
        loggedAt: now.subtract(const Duration(days: 2)),
      );

      final item2 = FoodLogEntry(
        barcode: '8901063012134',
        name: 'Parle-G',
        brand: 'Parle',
        portionLabel: '1 biscuit',
        portionAmount: 5.0,
        portionBasis: 'g',
        sugarGrams: 2.5,
        loggedAt: now.subtract(const Duration(days: 1)),
      );

      final item3 = FoodLogEntry(
        barcode: '8901063012134',
        name: 'Parle-G',
        brand: 'Parle',
        portionLabel: '1 biscuit (x2)',
        portionAmount: 10.0,
        portionBasis: 'g',
        sugarGrams: 5.1,
        loggedAt: now,
      );

      final itemUnknown = FoodLogEntry(
        barcode: '0004614504046',
        name: 'Aquafina',
        brand: 'Generic',
        portionLabel: '1 cup',
        portionAmount: 30.0,
        portionBasis: 'ml',
        sugarGrams: null, // Unknown sugar must be ignored in ranking
        loggedAt: now,
      );

      final day1 = DailySugarSummary(
        date: now.subtract(const Duration(days: 2)),
        totalSugarGrams: 31.8,
        unknownSugarCount: 0,
        totalItemsCount: 1,
        targetLimitGrams: 25.0,
        items: [item1],
      );

      final day2 = DailySugarSummary(
        date: now.subtract(const Duration(days: 1)),
        totalSugarGrams: 2.5,
        unknownSugarCount: 0,
        totalItemsCount: 1,
        targetLimitGrams: 25.0,
        items: [item2],
      );

      final day3 = DailySugarSummary(
        date: now,
        totalSugarGrams: 5.1,
        unknownSugarCount: 1,
        totalItemsCount: 2,
        targetLimitGrams: 25.0,
        items: [item3, itemUnknown],
      );

      final analytics = WeeklyAnalytics(
        dailySummaries: [day1, day2, day3],
        dailyTargetGrams: 25.0,
      );

      final contributors = analytics.topContributors;

      // Ranked top sugar sources:
      // 1. Thums Up: 31.8g (1 log)
      // 2. Parle-G: 2.5 + 5.1 = 7.6g (2 logs)
      expect(contributors.length, 2);
      expect(contributors[0].name, 'Thums Up');
      expect(contributors[0].totalSugarGrams, 31.8);
      expect(contributors[0].logCount, 1);

      expect(contributors[1].name, 'Parle-G');
      expect(contributors[1].totalSugarGrams, 7.6);
      expect(contributors[1].logCount, 2);
    });

    test('handles empty week gracefully', () {
      final analytics = const WeeklyAnalytics(
        dailySummaries: [],
        dailyTargetGrams: 25.0,
      );

      expect(analytics.totalSugarGrams, 0.0);
      expect(analytics.averageDailySugarGrams, 0.0);
      expect(analytics.averageDailyTeaspoons, 0.0);
      expect(analytics.daysWithinLimit, 0);
      expect(analytics.daysOverLimit, 0);
      expect(analytics.highestSugarDay, isNull);
      expect(analytics.topContributors, isEmpty);
    });
  });
}
