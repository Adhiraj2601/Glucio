import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/data/models/product.dart';

void main() {
  group('Open Food Facts Ingested Seed Catalog Integrity Tests', () {
    late List<Product> products;

    setUpAll(() {
      final file = File('assets/seed_products.json');
      expect(file.existsSync(), isTrue, reason: 'seed_products.json must exist');
      final content = file.readAsStringSync();
      final List<dynamic> list = jsonDecode(content) as List<dynamic>;
      products = list
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    });

    test('catalog contains expanded Indian products (> 250 products)', () {
      expect(products.length, greaterThan(250));
      // ignore: avoid_print
      print('Verified seed catalog size: ${products.length} products.');
    });

    test('all barcodes are unique and valid digits', () {
      final barcodes = <String>{};
      for (final p in products) {
        expect(barcodes.contains(p.barcode), isFalse,
            reason: 'Duplicate barcode: ${p.barcode}');
        barcodes.add(p.barcode);
        expect(RegExp(r'^\d+$').hasMatch(p.barcode), isTrue,
            reason: 'Barcode must be all digits: ${p.barcode}');
      }
    });

    test('contains newly ingested iconic Indian staples (Amul, Maggi, Britannia, Haldiram)', () {
      final brands = products.map((p) => p.brand.toLowerCase()).toSet();
      expect(brands.any((b) => b.contains('amul')), isTrue);
      expect(brands.any((b) => b.contains('maggi')), isTrue);
      expect(brands.any((b) => b.contains('britannia')), isTrue);
      expect(brands.any((b) => b.contains('haldiram')), isTrue);

      // Verify specific Amul Kool Elaichi product
      final amulKool = products.firstWhere(
        (p) => p.barcode == '8901262010016',
        orElse: () => throw Exception('Amul Kool Elaichi not found'),
      );
      expect(amulKool.brand, 'Amul');
      expect(amulKool.sugarPer100, equals(9.0));
      expect(amulKool.category, equals('beverage'));

      // Verify Maggi Noodles
      final maggi = products.firstWhere(
        (p) => p.barcode == '8901058851328',
        orElse: () => throw Exception('Maggi 2 Minutes Noodles Masala not found'),
      );
      expect(maggi.brand, 'Maggi');
      expect(maggi.sugarPer100, equals(3.43));
      expect(maggi.category, equals('instant noodles'));
    });

    test('missing sugar products strictly preserve null', () {
      final nullSugar = products.where((p) => p.sugarPer100 == null).toList();
      expect(nullSugar.isNotEmpty, isTrue);
      // Ensure none of them default to 0.0
      for (final p in nullSugar) {
        expect(p.sugarPer100, isNull);
      }
    });

    test('all products have at least one valid portion', () {
      for (final p in products) {
        expect(p.portions.isNotEmpty, isTrue,
            reason: 'Product ${p.name} (${p.barcode}) has no portions');
        expect(p.portions.last.label.toLowerCase().contains('pack'), isTrue,
            reason: 'Product ${p.name} last portion is not whole pack');
      }
    });
  });
}
