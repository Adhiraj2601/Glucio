import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/main.dart';

void main() {
  testWidgets('Glucio Slice 1 smoke test - HomeScreen renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GlucioApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify app title and main actions
    expect(find.text('Glucio'), findsOneWidget);
    expect(find.text('Scan Food Barcode'), findsOneWidget);
    expect(find.text('Enter Barcode Manually (Debug / Testing)'), findsOneWidget);
    expect(find.text('Parle-G Gluco Biscuits'), findsOneWidget);
  });
}
