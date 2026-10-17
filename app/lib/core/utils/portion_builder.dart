import 'dart:convert';
import 'package:flutter/services.dart';
import '../../data/models/portion.dart';

/// Utility to build and merge natural household portions for any product.
class PortionBuilder {
  PortionBuilder._();

  static Map<String, List<Portion>> _categoryDefaults = {};
  static bool _defaultsLoaded = false;

  /// Loads category portion defaults from bundled JSON.
  static Future<void> initDefaults() async {
    if (_defaultsLoaded) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/portion_defaults.json');
      final Map<String, dynamic> decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      _categoryDefaults = decoded.map((key, value) {
        final list = (value as List<dynamic>)
            .map((item) => Portion.fromJson(item as Map<String, dynamic>))
            .toList();
        return MapEntry(key.toLowerCase(), list);
      });
      _defaultsLoaded = true;
    } catch (_) {
      // Fallback in-memory defaults if asset reading fails
      _categoryDefaults = {
        'sauces': const [
          Portion(label: '1 tsp', amount: 5.0, basis: 'g', kind: 'spoon', source: 'estimate'),
          Portion(label: '1 tbsp', amount: 15.0, basis: 'g', kind: 'spoon', source: 'estimate'),
        ],
        'ketchup': const [
          Portion(label: '1 tsp', amount: 5.0, basis: 'g', kind: 'spoon', source: 'estimate'),
          Portion(label: '1 tbsp', amount: 15.0, basis: 'g', kind: 'spoon', source: 'estimate'),
        ],
        'namkeen': const [
          Portion(label: '1 handful', amount: 25.0, basis: 'g', kind: 'handful', source: 'estimate'),
        ],
        'chips': const [
          Portion(label: '1 handful', amount: 25.0, basis: 'g', kind: 'handful', source: 'estimate'),
        ],
        'makhana': const [
          Portion(label: '1 handful', amount: 25.0, basis: 'g', kind: 'handful', source: 'estimate'),
        ],
        'beverage': const [
          Portion(label: '1 glass', amount: 200.0, basis: 'ml', kind: 'glass', source: 'estimate'),
        ],
        'health drink': const [
          Portion(label: '1 glass', amount: 200.0, basis: 'ml', kind: 'glass', source: 'estimate'),
        ],
      };
      _defaultsLoaded = true;
    }
  }

  /// Builds a complete list of portions for a product, combining:
  /// 1. Label-specific portions (e.g. from seed or user input)
  /// 2. Natural 1 unit if unitsPerPack is known
  /// 3. "1 serving" from label servingSize
  /// 4. Category generic fallbacks (source = "estimate")
  /// 5. "Whole pack" at the end (when packSize > 0)
  static List<Portion> buildPortions({
    required String category,
    required double packSize,
    required double servingSize,
    String? servingDescription,
    int? unitsPerPack,
    List<Portion>? customPortions,
    String basis = 'g',
  }) {
    final Map<String, Portion> result = {};

    // 1. Add custom or label-provided portions first
    if (customPortions != null) {
      for (final p in customPortions) {
        result[p.label.toLowerCase()] = p;
      }
    }

    // 2. Add per-unit portion if unitsPerPack is known
    if (unitsPerPack != null && unitsPerPack > 0 && packSize > 0) {
      final unitAmount = packSize / unitsPerPack;
      final unitLabel = _getUnitLabel(category);
      if (!result.containsKey(unitLabel.toLowerCase())) {
        result[unitLabel.toLowerCase()] = Portion(
          label: unitLabel,
          amount: double.parse(unitAmount.toStringAsFixed(1)),
          basis: basis,
          kind: 'unit',
          source: 'label',
        );
      }
    }

    // 3. Add category generic fallback estimates if not already covered
    final catKey = category.trim().toLowerCase();
    for (final entry in _categoryDefaults.entries) {
      if (catKey.contains(entry.key)) {
        for (final def in entry.value) {
          if (!result.containsKey(def.label.toLowerCase())) {
            result[def.label.toLowerCase()] = def;
          }
        }
      }
    }

    // 4. Add "1 serving" from label if not redundant with an existing portion of identical amount
    if (servingSize > 0) {
      final alreadyHasSameAmount = result.values.any(
        (p) => (p.amount - servingSize).abs() < 0.1,
      );
      if (!alreadyHasSameAmount) {
        final servingLabel = (servingDescription != null && servingDescription.isNotEmpty)
            ? '1 serving ($servingDescription)'
            : '1 serving (${servingSize.toStringAsFixed(0)}$basis)';
        if (!result.containsKey(servingLabel.toLowerCase())) {
          result[servingLabel.toLowerCase()] = Portion(
            label: servingLabel,
            amount: servingSize,
            basis: basis,
            kind: 'serving',
            source: 'label',
          );
        }
      }
    }

    // 5. Always place "Whole pack" at the end if packSize > 0
    Portion? wholePackPortion;
    if (packSize > 0) {
      wholePackPortion = Portion(
        label: 'Whole pack (${packSize.toStringAsFixed(0)}$basis)',
        amount: packSize,
        basis: basis,
        kind: 'pack',
        source: 'label',
      );
    }

    final portions = result.values.toList();
    // Sort so units / spoons are first, then servings, and whole pack is last
    portions.sort((a, b) {
      if (a.kind == 'pack') return 1;
      if (b.kind == 'pack') return -1;
      return a.amount.compareTo(b.amount);
    });

    if (wholePackPortion != null && !portions.any((p) => p.kind == 'pack')) {
      portions.add(wholePackPortion);
    }

    return portions;
  }

  static String _getUnitLabel(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('biscuit')) return '1 biscuit';
    if (cat.contains('bread')) return '1 slice';
    if (cat.contains('sweet') || cat.contains('mithai')) return '1 piece';
    if (cat.contains('chocolate') || cat.contains('confectionery')) return '1 piece';
    return '1 piece';
  }
}
