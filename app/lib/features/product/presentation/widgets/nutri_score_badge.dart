import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';

/// Interactive Neo-Brutalist 5-segment Nutri-Score badge (A to E).
class NutriScoreBadge extends StatelessWidget {
  final String? grade; // 'a', 'b', 'c', 'd', 'e'
  final Map<String, dynamic>? nutriScoreData;
  final VoidCallback? onTap;

  const NutriScoreBadge({
    super.key,
    this.grade,
    this.nutriScoreData,
    this.onTap,
  });

  static Color _getGradeColor(String g) {
    switch (g.toLowerCase()) {
      case 'a':
        return GlucioTheme.nutriScoreA;
      case 'b':
        return GlucioTheme.nutriScoreB;
      case 'c':
        return GlucioTheme.nutriScoreC;
      case 'd':
        return GlucioTheme.nutriScoreD;
      case 'e':
        return GlucioTheme.nutriScoreE;
      default:
        return GlucioTheme.levelMissing;
    }
  }

  static String _getGradeDescription(String g) {
    switch (g.toLowerCase()) {
      case 'a':
        return 'Very good nutritional quality';
      case 'b':
        return 'Good nutritional quality';
      case 'c':
        return 'Average nutritional quality';
      case 'd':
        return 'Poor nutritional quality';
      case 'e':
        return 'Lower nutritional quality';
      default:
        return 'Not computed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanGrade = grade?.toLowerCase().trim();
    final hasValidGrade = cleanGrade != null &&
        ['a', 'b', 'c', 'd', 'e'].contains(cleanGrade);

    if (!hasValidGrade) {
      return InkWell(
        onTap: () => _showExplanationSheet(context, null),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: GlucioTheme.cardCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GlucioTheme.inkBlack, width: 2),
            boxShadow: const [
              BoxShadow(
                color: GlucioTheme.inkBlack,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: GlucioTheme.levelMissing,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Nutri-Score: Not computed',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: GlucioTheme.inkBlack,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          _showExplanationSheet(context, cleanGrade);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: GlucioTheme.cardCream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GlucioTheme.inkBlack, width: 2),
          boxShadow: const [
            BoxShadow(
              color: GlucioTheme.inkBlack,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'NUTRI-SCORE',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontDisplay,
                    fontSize: 12,
                    letterSpacing: 0.5,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: GlucioTheme.inkBlack,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: ['a', 'b', 'c', 'd', 'e'].map((letter) {
                final isSelected = letter == cleanGrade;
                final color = _getGradeColor(letter);

                return Container(
                  margin: const EdgeInsets.only(right: 3),
                  width: isSelected ? 28 : 20,
                  height: isSelected ? 32 : 22,
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(isSelected ? 8 : 4),
                    border: Border.all(
                      color: GlucioTheme.inkBlack,
                      width: isSelected ? 2 : 1,
                    ),
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
                    letter.toUpperCase(),
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontDisplay,
                      fontSize: isSelected ? 16 : 11,
                      color: isSelected ? Colors.white : GlucioTheme.inkBlack,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showExplanationSheet(BuildContext context, String? activeGrade) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _NutriScoreBottomSheet(
        grade: activeGrade,
        data: nutriScoreData,
      ),
    );
  }
}

class _NutriScoreBottomSheet extends StatelessWidget {
  final String? grade;
  final Map<String, dynamic>? data;

  const _NutriScoreBottomSheet({this.grade, this.data});

  @override
  Widget build(BuildContext context) {
    final gradeUpper = grade?.toUpperCase() ?? '?';
    final gradeColor = grade != null
        ? NutriScoreBadge._getGradeColor(grade!)
        : GlucioTheme.levelMissing;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: GlucioTheme.bgCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: GlucioTheme.inkBlack, width: 3),
          left: BorderSide(color: GlucioTheme.inkBlack, width: 3),
          right: BorderSide(color: GlucioTheme.inkBlack, width: 3),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: GlucioTheme.inkBlack,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: gradeColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: GlucioTheme.inkBlack,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      gradeUpper,
                      style: const TextStyle(
                        fontFamily: GlucioTheme.fontDisplay,
                        fontSize: 26,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nutri-Score $gradeUpper',
                          style: const TextStyle(
                            fontFamily: GlucioTheme.fontDisplay,
                            fontSize: 22,
                            color: GlucioTheme.inkBlack,
                          ),
                        ),
                        Text(
                          grade != null
                              ? NutriScoreBadge._getGradeDescription(grade!)
                              : 'Not available for this item',
                          style: const TextStyle(
                            fontFamily: GlucioTheme.fontBody,
                            fontSize: 13,
                            color: GlucioTheme.inkBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: GlucioTheme.cardCream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                ),
                child: const Text(
                  'The Nutri-Score is an independent front-of-pack nutritional quality score from A (best) to E (worst), calculated per 100g based on positive nutrients (fiber, protein, fruit/veg) minus negative components (energy, sugar, saturated fat, sodium).',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 12,
                    height: 1.4,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
              ),
              if (data != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'CALCULATION BREAKDOWN',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontDisplay,
                    fontSize: 14,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
                const SizedBox(height: 10),
                _buildPointsRow('Negative Points (Energy, Sugar, Sat-Fat, Salt)',
                    data!['negative_points']?.toString() ?? '—', GlucioTheme.levelHigh),
                const SizedBox(height: 8),
                _buildPointsRow('Positive Points (Fiber, Protein, Fruits/Veg)',
                    data!['positive_points']?.toString() ?? '—', GlucioTheme.levelLow),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EFEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: GlucioTheme.inkBlack),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This score complements the nutrition label and does not replace official food regulations.',
                        style: TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontSize: 11,
                          color: GlucioTheme.inkBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: GlucioTheme.cardCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 12,
                color: GlucioTheme.inkBlack,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: GlucioTheme.fontDisplay,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
