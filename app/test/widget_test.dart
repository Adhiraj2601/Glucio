import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/main.dart';

void main() {
  testWidgets('Glucio Slice 0 smoke test', (WidgetTester tester) async {
    // Build GlucioApp and trigger a frame
    await tester.pumpWidget(const GlucioApp());

    // Verify app title and Slice 0 elements are rendered
    expect(find.text('Glucio'), findsOneWidget);
    expect(find.text('Slice 0: Environment & Scaffold Ready'), findsOneWidget);
    expect(find.text('com.glucio.app (Fixed)'), findsOneWidget);
    expect(find.text('Configured in Manifest'), findsNWidgets(2));
  });
}
