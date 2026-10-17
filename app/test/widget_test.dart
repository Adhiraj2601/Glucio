import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glucio/main.dart';

void main() {
  testWidgets('GlucioApp smoke test renders HomeScreen with title and scanner button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GlucioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Glucio'), findsOneWidget);
    expect(find.text('Scan Food Barcode'), findsOneWidget);
    expect(find.text('Launch Camera Scanner'), findsOneWidget);
    expect(find.text('Quick Test Products'), findsOneWidget);
  });
}
