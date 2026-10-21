import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../data/models/product_details.dart';

/// Interactive Neo-Brutalist Nutrition Facts Card with 100g vs Serving toggle.
class NutritionFactsCard extends StatefulWidget {
  final FullNutriments? nutriments;
  final NutrientLevels? levels;
  final String? servingDescription;

  const NutritionFactsCard({
    super.key,
    this.nutriments,
    this.levels,
    this.servingDescription,
  });

  @override
  State<NutritionFactsCard> createState() => _NutritionFactsCardState();
}

class _NutritionFactsCardState extends State<NutritionFactsCard> {
  bool _showPerServing = false;

  Color _getLevelDotColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'low':
        return GlucioTheme.levelLow;
      case 'moderate':
        return GlucioTheme.levelMedium;
      case 'high':
        return GlucioTheme.levelHigh;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.nutriments;
    if (n == null) {
      return const Text(
        'Detailed nutrient breakdown not available in the database.',
        style: TextStyle(
          fontFamily: GlucioTheme.fontBody,
          fontSize: 12,
          color: Colors.black54,
        ),
      );
    }

    final hasServingData = n.sugarsServing != null ||
        n.energyKcalServing != null ||
        n.fatServing != null;

    final energy = _showPerServing ? n.energyKcalServing : n.energyKcal100g;
    final fat = _showPerServing ? n.fatServing : n.fat100g;
    final satFat = _showPerServing ? n.saturatedFatServing : n.saturatedFat100g;
    final carbs = _showPerServing ? n.carbohydratesServing : n.carbohydrates100g;
    final sugars = _showPerServing ? n.sugarsServing : n.sugars100g;
    final fiber = _showPerServing ? n.fiberServing : n.fiber100g;
    final protein = _showPerServing ? n.proteinsServing : n.proteins100g;
    final salt = _showPerServing ? n.saltServing : n.salt100g;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasServingData) ...[
          Row(
            children: [
              Expanded(
                child: _buildToggleOption('Per 100g', !_showPerServing, () {
                  setState(() => _showPerServing = false);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToggleOption(
                  widget.servingDescription ?? 'Per Serving',
                  _showPerServing,
                  () {
                    setState(() => _showPerServing = true);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Container(
          decoration: BoxDecoration(
            color: GlucioTheme.cardCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
          ),
          child: Column(
            children: [
              _buildNutrientRow('Energy', energy != null ? '${energy.toStringAsFixed(0)} kcal' : '—'),
              _buildDivider(),
              _buildNutrientRow('Total Fat', fat != null ? '${fat.toStringAsFixed(1)} g' : '—',
                  dotColor: _getLevelDotColor(widget.levels?.fat)),
              _buildDivider(),
              _buildNutrientRow('  • Saturated Fat', satFat != null ? '${satFat.toStringAsFixed(1)} g' : '—',
                  isSubRow: true, dotColor: _getLevelDotColor(widget.levels?.saturatedFat)),
              _buildDivider(),
              _buildNutrientRow('Carbohydrates', carbs != null ? '${carbs.toStringAsFixed(1)} g' : '—'),
              _buildDivider(),
              _buildNutrientRow('  • Sugars', sugars != null ? '${sugars.toStringAsFixed(1)} g' : '—',
                  isSubRow: true,
                  isHeroHighlight: true,
                  dotColor: _getLevelDotColor(widget.levels?.sugars)),
              _buildDivider(),
              _buildNutrientRow('Dietary Fiber', fiber != null ? '${fiber.toStringAsFixed(1)} g' : '—'),
              _buildDivider(),
              _buildNutrientRow('Proteins', protein != null ? '${protein.toStringAsFixed(1)} g' : '—'),
              _buildDivider(),
              _buildNutrientRow('Salt', salt != null ? '${salt.toStringAsFixed(2)} g' : '—',
                  dotColor: _getLevelDotColor(widget.levels?.salt)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? GlucioTheme.accentLime : GlucioTheme.cardCream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: GlucioTheme.inkBlack,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: GlucioTheme.fontBody,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: GlucioTheme.inkBlack,
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientRow(
    String label,
    String value, {
    bool isSubRow = false,
    bool isHeroHighlight = false,
    Color dotColor = Colors.transparent,
  }) {
    return Container(
      color: isHeroHighlight ? GlucioTheme.accentLime.withValues(alpha: 0.18) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          if (dotColor != Colors.transparent) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 12,
                fontWeight: (isSubRow && !isHeroHighlight) ? FontWeight.normal : FontWeight.bold,
                color: GlucioTheme.inkBlack,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: isHeroHighlight ? GlucioTheme.fontDisplay : GlucioTheme.fontBody,
              fontSize: isHeroHighlight ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: GlucioTheme.inkBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: const Color(0xFFE5E0D5));
  }
}
