import 'package:flutter/material.dart';
import '../../../../data/models/product_details.dart';
import 'eco_score_badge.dart';
import 'nova_badge.dart';
import 'nutri_score_badge.dart';
import 'nutrient_level_chips.dart';

/// Horizontal row of Neo-Brutalist nutritional quality assessment widgets.
class ProductQualityRow extends StatelessWidget {
  final ProductDetails? details;
  final double? sugarGrams;
  final bool showEcoScore;
  final VoidCallback? onSugarTapped;

  const ProductQualityRow({
    super.key,
    this.details,
    this.sugarGrams,
    this.showEcoScore = false,
    this.onSugarTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              NutriScoreBadge(
                grade: details?.nutriScoreGrade,
                nutriScoreData: details?.nutriScoreData,
              ),
              const SizedBox(width: 10),
              NovaBadge(
                group: details?.novaGroup,
                additiveTags: details?.additiveTags ?? const [],
              ),
              if (showEcoScore && details?.ecoScoreGrade != null) ...[
                const SizedBox(width: 10),
                EcoScoreBadge(
                  grade: details?.ecoScoreGrade,
                  ecoScoreData: details?.ecoScoreData,
                ),
              ],
            ],
          ),
        ),
        if (details?.nutrientLevels != null) ...[
          const SizedBox(height: 12),
          NutrientLevelChips(
            levels: details!.nutrientLevels,
            sugarGrams: sugarGrams,
            onSugarTapped: onSugarTapped,
          ),
        ],
      ],
    );
  }
}
