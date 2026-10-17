/// Represents a recognizable household portion (1 tbsp, 1 biscuit, 1 glass, whole pack, etc.)
class Portion {
  final String label;
  final double amount;
  final String basis; // 'g' or 'ml'
  final String kind; // 'unit' | 'spoon' | 'handful' | 'glass' | 'serving' | 'pack'
  final String source; // 'label' | 'estimate'

  const Portion({
    required this.label,
    required this.amount,
    this.basis = 'g',
    required this.kind,
    required this.source,
  });

  bool get isEstimate => source == 'estimate';

  factory Portion.fromJson(Map<String, dynamic> json) {
    return Portion(
      label: json['label']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      basis: json['basis']?.toString() ?? 'g',
      kind: json['kind']?.toString() ?? 'serving',
      source: json['source']?.toString() ?? 'label',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'amount': amount,
      'basis': basis,
      'kind': kind,
      'source': source,
    };
  }

  /// Parses a string formatted as "label=amount" (e.g. "1 tbsp=15" or "1 biscuit=12.5")
  static Portion? parseSimple(String entry, {String defaultBasis = 'g', String defaultKind = 'unit'}) {
    final parts = entry.split('=');
    if (parts.length != 2) return null;
    final label = parts[0].trim();
    final amount = double.tryParse(parts[1].trim());
    if (amount == null || amount <= 0) return null;

    final lower = label.toLowerCase();
    String kind = defaultKind;
    if (lower.contains('tbsp') || lower.contains('tsp') || lower.contains('spoon')) {
      kind = 'spoon';
    } else if (lower.contains('handful')) {
      kind = 'handful';
    } else if (lower.contains('glass') || lower.contains('cup')) {
      kind = 'glass';
    } else if (lower.contains('pack')) {
      kind = 'pack';
    } else if (lower.contains('serving')) {
      kind = 'serving';
    }

    return Portion(
      label: label,
      amount: amount,
      basis: defaultBasis,
      kind: kind,
      source: 'label',
    );
  }
}
