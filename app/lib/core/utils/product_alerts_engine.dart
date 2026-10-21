import '../../data/models/product.dart';
import '../../data/models/product_alert_verdict.dart';
import '../../data/models/product_details.dart';
import '../../data/models/user_preferences.dart';
import 'additive_risk_lookup.dart';

/// Pure Dart rules engine that evaluates a product against user dietary preferences.
class ProductAlertsEngine {
  ProductAlertsEngine._();

  static const Map<String, List<String>> _allergenKeywords = {
    'allergen_milk': ['milk', 'dairy', 'lactose', 'whey', 'casein', 'butter', 'cream', 'cheese'],
    'allergen_gluten': ['gluten', 'wheat', 'barley', 'rye', 'malt', 'atta', 'maida', 'semolina'],
    'allergen_peanuts': ['peanut', 'groundnut', 'arachis'],
    'allergen_soy': ['soy', 'soya', 'edamame'],
    'allergen_tree_nuts': ['almond', 'cashew', 'walnut', 'pistachio', 'hazelnut', 'pecan'],
    'allergen_eggs': ['egg', 'albumin', 'yolk'],
    'allergen_fish': ['fish', 'crustacean', 'shrimp', 'prawn', 'crab', 'gelatin'],
    'allergen_mustard': ['mustard', 'sarson', 'rai'],
    'allergen_sesame': ['sesame', 'til', 'tahini'],
  };

  /// Evaluates a [product] (or standalone [details]) against the active [preferences].
  static ProductAlertVerdict evaluate({
    required UserPreferences preferences,
    Product? product,
    ProductDetails? details,
  }) {
    final effectiveDetails = details ?? product?.details;
    final sugar100 = product?.sugarPer100 ?? effectiveDetails?.fullNutriments?.sugars100g;

    final activeCriteria = preferences.activeCriteria;
    if (activeCriteria.isEmpty) {
      return ProductAlertVerdict.matches(summary: 'No dietary restrictions configured');
    }

    final violations = <String>[];
    final matched = <String>[];
    final unknowns = <String>[];
    bool hasMandatoryViolation = false;

    for (final criterion in activeCriteria) {
      final isMandatory = criterion.importance == PreferenceImportance.mandatory;

      // 1. ALLERGENS
      if (criterion.category == PreferenceCategory.allergen) {
        final keywords = _allergenKeywords[criterion.id] ?? [];
        final hasAllergenInfo = (effectiveDetails?.allergenTags.isNotEmpty ?? false) ||
            (effectiveDetails?.ingredientsText?.isNotEmpty ?? false);

        if (!hasAllergenInfo) {
          if (isMandatory) {
            unknowns.add('${criterion.label} status unknown');
          }
          continue;
        }

        bool detected = false;
        // Check tags
        for (final tag in (effectiveDetails?.allergenTags ?? <String>[])) {
          final cleanTag = tag.toLowerCase().replaceAll('en:', '');
          if (keywords.any((k) => cleanTag.contains(k))) {
            detected = true;
            break;
          }
        }

        // Check ingredients text fallback
        if (!detected && effectiveDetails?.ingredientsText != null) {
          final ingLower = effectiveDetails!.ingredientsText!.toLowerCase();
          if (keywords.any((k) => ingLower.contains(k))) {
            detected = true;
          }
        }

        if (detected) {
          violations.add('Contains ${criterion.label}');
          if (isMandatory) hasMandatoryViolation = true;
        } else {
          matched.add(criterion.label);
        }
      }

      // 2. DIETARY RESTRICTIONS
      else if (criterion.category == PreferenceCategory.diet) {
        final analysis = effectiveDetails?.ingredientsAnalysis;
        if (criterion.id == 'diet_vegetarian') {
          if (analysis == null || analysis.vegetarian == 'unknown') {
            if (isMandatory) unknowns.add('Vegetarian status unknown');
          } else if (analysis.vegetarian == 'no') {
            violations.add('Not Vegetarian');
            if (isMandatory) hasMandatoryViolation = true;
          } else {
            matched.add('Vegetarian');
          }
        } else if (criterion.id == 'diet_vegan') {
          if (analysis == null || analysis.vegan == 'unknown') {
            if (isMandatory) unknowns.add('Vegan status unknown');
          } else if (analysis.vegan == 'no') {
            violations.add('Not Vegan');
            if (isMandatory) hasMandatoryViolation = true;
          } else {
            matched.add('Vegan');
          }
        } else if (criterion.id == 'diet_palm_oil_free') {
          if (analysis == null || analysis.palmOil == 'unknown') {
            if (isMandatory) unknowns.add('Palm oil status unknown');
          } else if (analysis.palmOil == 'yes') {
            violations.add('Contains Palm Oil');
            if (isMandatory) hasMandatoryViolation = true;
          } else {
            matched.add('Palm Oil Free');
          }
        }
      }

      // 3. NUTRITION PRIORITIES
      else if (criterion.category == PreferenceCategory.nutrition) {
        if (criterion.id == 'nutr_low_sugar') {
          final sugarLevel = effectiveDetails?.nutrientLevels?.sugars?.toLowerCase();
          if (sugarLevel == 'high' || (sugar100 != null && sugar100 > 15.0)) {
            violations.add('High Sugar (${sugar100?.toStringAsFixed(1) ?? '>15'}g/100g)');
            if (isMandatory) hasMandatoryViolation = true;
          } else if (sugarLevel == 'low' || (sugar100 != null && sugar100 <= 5.0)) {
            matched.add('Low Sugar');
          }
        } else if (criterion.id == 'nutr_low_salt') {
          final saltLevel = effectiveDetails?.nutrientLevels?.salt?.toLowerCase();
          if (saltLevel == 'high') {
            violations.add('High Salt');
            if (isMandatory) hasMandatoryViolation = true;
          } else if (saltLevel == 'low') {
            matched.add('Low Salt');
          }
        } else if (criterion.id == 'nutr_low_fat') {
          final satFatLevel = effectiveDetails?.nutrientLevels?.saturatedFat?.toLowerCase();
          if (satFatLevel == 'high') {
            violations.add('High Saturated Fat');
            if (isMandatory) hasMandatoryViolation = true;
          } else if (satFatLevel == 'low') {
            matched.add('Low Saturated Fat');
          }
        }
      }

      // 4. PROCESSING & ADDITIVES
      else if (criterion.category == PreferenceCategory.processing) {
        if (criterion.id == 'proc_avoid_ultra_processed') {
          final nova = effectiveDetails?.novaGroup;
          if (nova == 4) {
            violations.add('Ultra-processed food (NOVA 4)');
            if (isMandatory) hasMandatoryViolation = true;
          } else if (nova != null && nova <= 2) {
            matched.add('Minimally processed (NOVA $nova)');
          } else if (nova == null && isMandatory) {
            unknowns.add('NOVA processing score unknown');
          }
        } else if (criterion.id == 'proc_avoid_additives') {
          final highRisk = effectiveDetails?.additives
                  .where((a) => a.riskLevel == AdditiveRiskLevel.high)
                  .toList() ??
              [];
          if (highRisk.isNotEmpty) {
            violations.add('Contains ${highRisk.length} high-risk additive(s)');
            if (isMandatory) hasMandatoryViolation = true;
          } else if ((effectiveDetails?.additiveTags.isNotEmpty ?? false)) {
            matched.add('No high-risk additives');
          }
        }
      }

      // 5. ENVIRONMENT
      else if (criterion.category == PreferenceCategory.environment) {
        if (criterion.id == 'env_good_ecoscore') {
          final eco = effectiveDetails?.ecoScoreGrade?.toLowerCase();
          if (eco != null && eco.isNotEmpty) {
            if (eco == 'd' || eco == 'e') {
              violations.add('High environmental impact (Eco-Score ${eco.toUpperCase()})');
              if (isMandatory) hasMandatoryViolation = true;
            } else if (eco == 'a' || eco == 'b') {
              matched.add('Eco-Score ${eco.toUpperCase()}');
            }
          } else if (isMandatory) {
            unknowns.add('Eco-Score unknown');
          }
        }
      }
    }

    if (violations.isNotEmpty) {
      return ProductAlertVerdict.violates(
        reason: violations.first,
        isMandatory: hasMandatoryViolation,
        violations: violations,
      );
    }

    if (unknowns.isNotEmpty) {
      return ProductAlertVerdict.unknown(
        reason: unknowns.first,
        unknowns: unknowns,
      );
    }

    return ProductAlertVerdict.matches(
      summary: 'Matches your preferences',
      matched: matched,
    );
  }
}
