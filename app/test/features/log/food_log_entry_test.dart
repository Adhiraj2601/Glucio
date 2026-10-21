import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/data/models/food_log_entry.dart';

void main() {
  group('FoodLogEntry Model Tests', () {
    test('creates entry with known sugar and computes teaspoons', () {
      final entry = FoodLogEntry(
        id: 1,
        barcode: '8901030383708',
        name: 'Parle-G Gold',
        brand: 'Parle',
        portionLabel: '4 biscuits (20g)',
        portionAmount: 20.0,
        portionBasis: 'g',
        sugarGrams: 5.3,
        loggedAt: DateTime(2026, 10, 21, 14, 30),
      );

      expect(entry.id, equals(1));
      expect(entry.barcode, equals('8901030383708'));
      expect(entry.name, equals('Parle-G Gold'));
      expect(entry.sugarGrams, equals(5.3));
      expect(entry.teaspoons, closeTo(1.325, 0.001));
    });

    test('preserves null sugar strictly and returns null for teaspoons', () {
      final entry = FoodLogEntry(
        barcode: '89080443',
        name: 'Maggi Tomato Sauce (Missing Sugar)',
        portionLabel: '1 tbsp (15g)',
        portionAmount: 15.0,
        portionBasis: 'g',
        sugarGrams: null,
        loggedAt: DateTime(2026, 10, 21, 14, 35),
      );

      expect(entry.sugarGrams, isNull);
      expect(entry.teaspoons, isNull);
    });

    test('serializes toMap and fromMap with known sugar', () {
      final now = DateTime.now();
      final entry = FoodLogEntry(
        id: 42,
        barcode: '8901491101835',
        name: 'Kurkure Masala Munch',
        brand: 'Kurkure',
        portionLabel: '1 serving (30g)',
        portionAmount: 30.0,
        portionBasis: 'g',
        sugarGrams: 0.6,
        loggedAt: now,
      );

      final map = entry.toMap();
      expect(map['id'], equals(42));
      expect(map['barcode'], equals('8901491101835'));
      expect(map['sugar_grams'], equals(0.6));

      final restored = FoodLogEntry.fromMap(map);
      expect(restored.id, equals(42));
      expect(restored.name, equals('Kurkure Masala Munch'));
      expect(restored.sugarGrams, equals(0.6));
    });

    test('serializes toMap and fromMap with null sugar without defaulting to 0', () {
      final now = DateTime.now();
      final entry = FoodLogEntry(
        barcode: '12345678',
        name: 'Unverified Snack',
        portionLabel: 'Whole pack (100g)',
        portionAmount: 100.0,
        portionBasis: 'g',
        sugarGrams: null,
        loggedAt: now,
      );

      final map = entry.toMap();
      expect(map['sugar_grams'], isNull);

      final restored = FoodLogEntry.fromMap(map);
      expect(restored.sugarGrams, isNull);
    });

    test('copyWith updates specified fields correctly', () {
      final entry = FoodLogEntry(
        barcode: '8901030383708',
        name: 'Parle-G',
        portionLabel: '2 biscuits (10g)',
        portionAmount: 10.0,
        sugarGrams: 2.6,
        loggedAt: DateTime(2026, 10, 21),
      );

      final updated = entry.copyWith(
        id: 99,
        portionLabel: '4 biscuits (20g)',
        portionAmount: 20.0,
        sugarGrams: 5.2,
      );

      expect(updated.id, equals(99));
      expect(updated.portionLabel, equals('4 biscuits (20g)'));
      expect(updated.portionAmount, equals(20.0));
      expect(updated.sugarGrams, equals(5.2));
      expect(updated.barcode, equals('8901030383708'));
    });
  });
}
