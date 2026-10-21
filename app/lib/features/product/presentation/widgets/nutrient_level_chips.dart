import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../data/models/product_details.dart';

/// Interactive Neo-Brutalist nutrient level chips (Sugar, Salt, Fat, Sat Fat).
class NutrientLevelChips extends StatelessWidget {
  final NutrientLevels? levels;
  final double? sugarGrams;
  final VoidCallback? onSugarTapped;

  const NutrientLevelChips({
    super.key,
    this.levels,
    this.sugarGrams,
    this.onSugarTapped,
  });

  static Color _getLevelColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'low':
        return GlucioTheme.levelLow;
      case 'moderate':
        return GlucioTheme.levelMedium;
      case 'high':
        return GlucioTheme.levelHigh;
      default:
        return GlucioTheme.levelMissing;
    }
  }

  static String _formatLevel(String? level) {
    if (level == null || level.isEmpty) return '—';
    return level.substring(0, 1).toUpperCase() + level.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final sugars = levels?.sugars;
    final salt = levels?.salt;
    final fat = levels?.fat;
    final satFat = levels?.saturatedFat;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            label: 'Sugar',
            level: sugars,
            isSugarHeroLink: true,
            onTap: onSugarTapped,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Salt',
            level: salt,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Fat',
            level: fat,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Sat Fat',
            level: satFat,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required String? level,
    bool isSugarHeroLink = false,
    VoidCallback? onTap,
  }) {
    final color = _getLevelColor(level);
    final levelText = _formatLevel(level);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: GlucioTheme.cardCream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSugarHeroLink ? GlucioTheme.inkBlack : GlucioTheme.inkBlack,
            width: isSugarHeroLink ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: GlucioTheme.inkBlack,
              offset: isSugarHeroLink ? const Offset(2.5, 2.5) : const Offset(1.5, 1.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 11,
                fontWeight: isSugarHeroLink ? FontWeight.bold : FontWeight.w500,
                color: GlucioTheme.inkBlack,
              ),
            ),
            Text(
              levelText,
              style: TextStyle(
                fontFamily: GlucioTheme.fontDisplay,
                fontSize: 12,
                color: color == GlucioTheme.levelMissing ? GlucioTheme.inkBlack : color,
              ),
            ),
            if (isSugarHeroLink) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_upward_rounded,
                size: 11,
                color: GlucioTheme.inkBlack,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
