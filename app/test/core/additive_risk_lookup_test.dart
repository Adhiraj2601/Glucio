import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/core/utils/additive_risk_lookup.dart';

void main() {
  group('AdditiveRiskLookup Unit Tests', () {
    test('normalizes various tag formats to standard E-number key', () {
      expect(AdditiveRiskLookup.normalizeTag('en:e322'), 'e322');
      expect(AdditiveRiskLookup.normalizeTag('E-322'), 'e322');
      expect(AdditiveRiskLookup.normalizeTag('INS 322'), 'e322');
      expect(AdditiveRiskLookup.normalizeTag('322'), 'e322');
      expect(AdditiveRiskLookup.normalizeTag('en:E150d'), 'e150d');
    });

    test('correctly looks up low-risk common additives', () {
      final lecithins = AdditiveRiskLookup.lookup('en:e322');
      expect(lecithins.code, 'E322');
      expect(lecithins.name, 'Lecithins');
      expect(lecithins.riskLevel, AdditiveRiskLevel.low);
      expect(lecithins.function, 'Emulsifier');

      final bakingSoda = AdditiveRiskLookup.lookup('E500');
      expect(bakingSoda.code, 'E500');
      expect(bakingSoda.riskLevel, AdditiveRiskLevel.low);
    });

    test('correctly flags high-risk azo dyes and restricted additives', () {
      final tartrazine = AdditiveRiskLookup.lookup('E102');
      expect(tartrazine.code, 'E102');
      expect(tartrazine.riskLevel, AdditiveRiskLevel.high);

      final titaniumDioxide = AdditiveRiskLookup.lookup('en:e171');
      expect(titaniumDioxide.code, 'E171');
      expect(titaniumDioxide.riskLevel, AdditiveRiskLevel.high);

      final nitrite = AdditiveRiskLookup.lookup('E250');
      expect(nitrite.riskLevel, AdditiveRiskLevel.high);
    });

    test('correctly classifies moderate-risk caramel colors and emulsifiers', () {
      final caramel = AdditiveRiskLookup.lookup('e150d');
      expect(caramel.riskLevel, AdditiveRiskLevel.moderate);

      final monoDiglycerides = AdditiveRiskLookup.lookup('E471');
      expect(monoDiglycerides.riskLevel, AdditiveRiskLevel.moderate);
    });

    test('handles unknown E-numbers gracefully without throwing', () {
      final unknown = AdditiveRiskLookup.lookup('E9999');
      expect(unknown.code, 'E9999');
      expect(unknown.riskLevel, AdditiveRiskLevel.unknown);
      expect(unknown.name, 'E9999');
    });
  });
}
