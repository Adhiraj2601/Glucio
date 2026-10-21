import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glucio/data/models/food_log_entry.dart';
import 'package:glucio/features/log/presentation/providers/daily_tracker_providers.dart';

void main() {
  group('Daily Tracker Derived Providers Tests', () {
    test('todayTotalSugarProvider sums known sugar and ignores null sugar', () async {
      final sampleLogs = [
        FoodLogEntry(
          barcode: '8901030383708',
          name: 'Parle-G',
          portionLabel: '4 biscuits',
          portionAmount: 20.0,
          sugarGrams: 5.3,
          loggedAt: DateTime.now(),
        ),
        FoodLogEntry(
          barcode: '89080443',
          name: 'Maggi Sauce (Missing)',
          portionLabel: '1 tbsp',
          portionAmount: 15.0,
          sugarGrams: null, // missing sugar
          loggedAt: DateTime.now(),
        ),
        FoodLogEntry(
          barcode: '8901491101835',
          name: 'Kurkure Masala Munch',
          portionLabel: '1 pack',
          portionAmount: 85.0,
          sugarGrams: 1.7,
          loggedAt: DateTime.now(),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          todayFoodLogsProvider.overrideWith(() => MockTodayFoodLogsNotifier(sampleLogs)),
        ],
      );

      // Await async notifier resolution
      await container.read(todayFoodLogsProvider.future);

      final totalSugar = container.read(todayTotalSugarProvider);
      final unknownCount = container.read(todayUnknownSugarCountProvider);
      final totalTeaspoons = container.read(todayTotalTeaspoonsProvider);

      expect(totalSugar, closeTo(7.0, 0.001));
      expect(unknownCount, equals(1));
      expect(totalTeaspoons, closeTo(1.75, 0.001));
    });

    test('returns 0.0 sugar and 0 unknown when no logs exist today', () async {
      final container = ProviderContainer(
        overrides: [
          todayFoodLogsProvider.overrideWith(() => MockTodayFoodLogsNotifier([])),
        ],
      );

      // Await async notifier resolution
      await container.read(todayFoodLogsProvider.future);

      expect(container.read(todayTotalSugarProvider), equals(0.0));
      expect(container.read(todayUnknownSugarCountProvider), equals(0));
      expect(container.read(todayTotalTeaspoonsProvider), equals(0.0));
    });
  });
}

class MockTodayFoodLogsNotifier extends TodayFoodLogsNotifier {
  final List<FoodLogEntry> _initialLogs;

  MockTodayFoodLogsNotifier(this._initialLogs);

  @override
  Future<List<FoodLogEntry>> build() async {
    return _initialLogs;
  }
}
