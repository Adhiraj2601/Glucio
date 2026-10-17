import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/core/utils/portion_builder.dart';
import 'package:glucio/data/models/portion.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await PortionBuilder.initDefaults();
  });

  group('PortionBuilder Tests', () {
    test('builds portions for biscuits with units per pack', () {
      final portions = PortionBuilder.buildPortions(
        category: 'biscuits',
        packSize: 250.0,
        servingSize: 25.0,
        unitsPerPack: 25,
      );

      // Should include 1 biscuit (10g), 1 serving (25g), and Whole pack (250g)
      expect(portions.any((p) => p.label == '1 biscuit' && p.amount == 10.0), isTrue);
      expect(portions.any((p) => p.label.contains('1 serving')), isTrue);
      expect(portions.last.kind, 'pack');
      expect(portions.last.amount, 250.0);
    });

    test('builds category default estimates for sauces and ketchup (1 tsp, 1 tbsp)', () {
      final portions = PortionBuilder.buildPortions(
        category: 'sauces',
        packSize: 500.0,
        servingSize: 15.0,
      );

      expect(portions.any((p) => p.label == '1 tsp' && p.source == 'estimate'), isTrue);
      expect(portions.any((p) => p.label == '1 tbsp' && p.source == 'estimate'), isTrue);
      expect(portions.last.kind, 'pack');
    });

    test('always places Whole pack at the end', () {
      final portions = PortionBuilder.buildPortions(
        category: 'namkeen',
        packSize: 200.0,
        servingSize: 30.0,
      );

      expect(portions.last.kind, 'pack');
      expect(portions.last.amount, 200.0);
    });

    test('preserves custom portions passed from seed data', () {
      final portions = PortionBuilder.buildPortions(
        category: 'biscuits',
        packSize: 120.0,
        servingSize: 30.0,
        customPortions: const [
          Portion(
            label: '2 biscuits',
            amount: 20.0,
            basis: 'g',
            kind: 'unit',
            source: 'label',
          ),
        ],
      );

      expect(portions.any((p) => p.label == '2 biscuits'), isTrue);
    });
  });
}
