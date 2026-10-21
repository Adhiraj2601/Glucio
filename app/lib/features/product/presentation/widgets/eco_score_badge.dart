import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';

/// Interactive Neo-Brutalist Eco-Score badge (A to E).
class EcoScoreBadge extends StatelessWidget {
  final String? grade; // 'a', 'b', 'c', 'd', 'e'
  final Map<String, dynamic>? ecoScoreData;
  final VoidCallback? onTap;

  const EcoScoreBadge({
    super.key,
    this.grade,
    this.ecoScoreData,
    this.onTap,
  });

  static Color _getGradeColor(String? g) {
    switch (g?.toLowerCase()) {
      case 'a':
        return GlucioTheme.ecoScoreA;
      case 'b':
        return GlucioTheme.ecoScoreB;
      case 'c':
        return GlucioTheme.ecoScoreC;
      case 'd':
        return GlucioTheme.ecoScoreD;
      case 'e':
        return GlucioTheme.ecoScoreE;
      default:
        return GlucioTheme.levelMissing;
    }
  }

  static String _getGradeTitle(String? g) {
    switch (g?.toLowerCase()) {
      case 'a':
        return 'Very low environmental impact';
      case 'b':
        return 'Low environmental impact';
      case 'c':
        return 'Moderate environmental impact';
      case 'd':
        return 'High environmental impact';
      case 'e':
        return 'Very high environmental impact';
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
        onTap: () => _showExplanationSheet(context),
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
                'Eco-Score: Not computed',
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

    final color = _getGradeColor(cleanGrade);

    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          _showExplanationSheet(context);
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
                  'ECO-SCORE',
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
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: GlucioTheme.inkBlack,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    cleanGrade.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontDisplay,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Eco-Score ${cleanGrade.toUpperCase()}',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExplanationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _EcoScoreBottomSheet(
        grade: grade,
        ecoScoreData: ecoScoreData,
      ),
    );
  }
}

class _EcoScoreBottomSheet extends StatelessWidget {
  final String? grade;
  final Map<String, dynamic>? ecoScoreData;

  const _EcoScoreBottomSheet({this.grade, this.ecoScoreData});

  @override
  Widget build(BuildContext context) {
    final gradeUpper = grade?.toUpperCase() ?? '?';
    final color = EcoScoreBadge._getGradeColor(grade);
    final title = EcoScoreBadge._getGradeTitle(grade);

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
                      color: color,
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
                          'Eco-Score $gradeUpper',
                          style: const TextStyle(
                            fontFamily: GlucioTheme.fontDisplay,
                            fontSize: 22,
                            color: GlucioTheme.inkBlack,
                          ),
                        ),
                        Text(
                          title,
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
                  'The Eco-Score is an experimental environmental indicator assessing the ecological footprint of food products from life cycle analysis (production, transport, packaging, deforestation risk).',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 12,
                    height: 1.4,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
              ),
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
                        'This score is calculated by Open Food Facts and complements the label.',
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
}
