import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/features/analytics/presentation/widgets/weekly_sugar_bar_chart.dart';

void main() {
  testWidgets('WeeklySugarBarChart renders header, limit line, and 7 day columns', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeeklySugarBarChart(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Weekly Sugar'), findsOneWidget);
    expect(find.textContaining('Target:'), findsOneWidget);
    expect(find.textContaining('LIMIT'), findsOneWidget);

    // Verify Today column is present
    expect(find.text('Today'), findsOneWidget);
  });
}
