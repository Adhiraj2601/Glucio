import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/data/models/food_log_entry.dart';
import 'package:glucio/features/analytics/presentation/providers/weekly_tracker_providers.dart';
import 'package:glucio/features/history/presentation/food_history_screen.dart';

void main() {
  testWidgets('FoodHistoryScreen renders empty state when no logs exist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allFoodLogsHistoryProvider.overrideWith(
            () => _FakeAllFoodLogsNotifier([]),
          ),
        ],
        child: const MaterialApp(
          home: FoodHistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Food History'), findsOneWidget);
    expect(find.text('No food logged yet'), findsOneWidget);
  });

  testWidgets('FoodHistoryScreen renders grouped list when logs exist', (tester) async {
    final sampleLogs = [
      FoodLogEntry(
        id: 1,
        barcode: '8901063012134',
        name: 'Parle-G Gluco Biscuits',
        brand: 'Parle',
        portionLabel: '1 biscuit (x2)',
        portionAmount: 10.0,
        portionBasis: 'g',
        sugarGrams: 5.1,
        loggedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allFoodLogsHistoryProvider.overrideWith(
            () => _FakeAllFoodLogsNotifier(sampleLogs),
          ),
        ],
        child: const MaterialApp(
          home: FoodHistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Food History'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Parle-G Gluco Biscuits'), findsOneWidget);
    expect(find.textContaining('5.1g sugar'), findsOneWidget);
  });
}

class _FakeAllFoodLogsNotifier extends AllFoodLogsNotifier {
  final List<FoodLogEntry> _initial;
  _FakeAllFoodLogsNotifier(this._initial);

  @override
  Future<List<FoodLogEntry>> build() async {
    return _initial;
  }
}
