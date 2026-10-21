/// Verdict status when comparing a product against user dietary preferences.
enum ProductAlertStatus {
  matches,
  violates,
  unknown;

  bool get isMatch => this == ProductAlertStatus.matches;
  bool get isViolation => this == ProductAlertStatus.violates;
  bool get isUnknown => this == ProductAlertStatus.unknown;
}

/// Result of evaluating a product against user preferences.
class ProductAlertVerdict {
  final ProductAlertStatus status;
  final String summary;
  final bool isMandatoryViolation;
  final List<String> violations;
  final List<String> matchedCriteria;
  final List<String> unknownCriteria;

  const ProductAlertVerdict({
    required this.status,
    required this.summary,
    this.isMandatoryViolation = false,
    this.violations = const [],
    this.matchedCriteria = const [],
    this.unknownCriteria = const [],
  });

  factory ProductAlertVerdict.matches({String? summary, List<String> matched = const []}) =>
      ProductAlertVerdict(
        status: ProductAlertStatus.matches,
        summary: summary ?? 'Matches your preferences',
        matchedCriteria: matched,
      );

  factory ProductAlertVerdict.violates({
    required String reason,
    bool isMandatory = false,
    List<String> violations = const [],
  }) =>
      ProductAlertVerdict(
        status: ProductAlertStatus.violates,
        summary: reason,
        isMandatoryViolation: isMandatory,
        violations: violations.isEmpty ? [reason] : violations,
      );

  factory ProductAlertVerdict.unknown({String? reason, List<String> unknowns = const []}) =>
      ProductAlertVerdict(
        status: ProductAlertStatus.unknown,
        summary: reason ?? "Can't verify ingredients",
        unknownCriteria: unknowns,
      );
}
