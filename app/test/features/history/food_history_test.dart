import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/data/models/food_log_entry.dart';
import 'package:glucio/data/models/product_list.dart';
import 'package:glucio/data/models/scan_history_entry.dart';
import 'package:glucio/data/repositories/off_repository.dart';
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
          scanHistoryProvider.overrideWith(
            () => _FakeScanHistoryNotifier([]),
          ),
          productListsProvider.overrideWith(
            () => _FakeProductListsNotifier([]),
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
          scanHistoryProvider.overrideWith(
            () => _FakeScanHistoryNotifier([]),
          ),
          productListsProvider.overrideWith(
            () => _FakeProductListsNotifier([]),
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

  testWidgets('FoodHistoryScreen switches to Scans segment and displays scans', (tester) async {
    final sampleScans = [
      ScanHistoryEntry(
        barcode: '8901491101837',
        name: 'Maggi 2-Minute Noodles',
        brand: 'Nestle',
        category: 'Instant Noodles',
        sugarPer100: 2.2,
        nutriScoreGrade: 'c',
        novaGroup: 4,
        scannedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allFoodLogsHistoryProvider.overrideWith(
            () => _FakeAllFoodLogsNotifier([]),
          ),
          scanHistoryProvider.overrideWith(
            () => _FakeScanHistoryNotifier(sampleScans),
          ),
          productListsProvider.overrideWith(
            () => _FakeProductListsNotifier([]),
          ),
        ],
        child: const MaterialApp(
          home: FoodHistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on the Scans tab
    await tester.tap(find.text('Scans'));
    await tester.pumpAndSettle();

    expect(find.text('Maggi 2-Minute Noodles'), findsOneWidget);
    expect(find.text('Nestle'), findsOneWidget);
    expect(find.textContaining('2.2g sugar'), findsOneWidget);
    expect(find.text('Clear History'), findsOneWidget);
  });

  testWidgets('FoodHistoryScreen switches to Lists segment and displays custom lists', (tester) async {
    final sampleLists = <ProductList>[
      ProductList(
        id: 'list_1',
        name: 'Low Sugar Snacks',
        createdAt: DateTime.now(),
        barcodes: const ['8901063012134'],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allFoodLogsHistoryProvider.overrideWith(
            () => _FakeAllFoodLogsNotifier([]),
          ),
          scanHistoryProvider.overrideWith(
            () => _FakeScanHistoryNotifier([]),
          ),
          productListsProvider.overrideWith(
            () => _FakeProductListsNotifier(sampleLists),
          ),
        ],
        child: const MaterialApp(
          home: FoodHistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on the Lists tab
    await tester.tap(find.text('Lists'));
    await tester.pumpAndSettle();

    expect(find.text('Low Sugar Snacks'), findsOneWidget);
    expect(find.text('1 products saved'), findsOneWidget);
    expect(find.text('+ Create New List'), findsOneWidget);
  });

  testWidgets('FoodHistoryScreen long press enters multi-select mode', (tester) async {
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
          scanHistoryProvider.overrideWith(
            () => _FakeScanHistoryNotifier([]),
          ),
          productListsProvider.overrideWith(
            () => _FakeProductListsNotifier([]),
          ),
        ],
        child: const MaterialApp(
          home: FoodHistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Long press on the item card
    await tester.longPress(find.text('Parle-G Gluco Biscuits'));
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Compare (1/4)'), findsOneWidget);
    expect(find.byIcon(Icons.share_rounded), findsOneWidget);
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

class _FakeScanHistoryNotifier extends ScanHistoryNotifier {
  final List<ScanHistoryEntry> _initial;
  _FakeScanHistoryNotifier(this._initial);

  @override
  Future<List<ScanHistoryEntry>> build() async {
    return _initial;
  }
}

class _FakeProductListsNotifier extends ProductListsNotifier {
  final List<ProductList> _initial;
  _FakeProductListsNotifier(this._initial);

  @override
  Future<List<ProductList>> build() async {
    return _initial;
  }
}
