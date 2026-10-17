import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';

/// Visual widget that renders sugar cubes for a given teaspoon count in Neo-brutalist style.
/// 1 sugar cube = 1 teaspoon = 4.0 grams.
/// Capped at 12 cubes max; displays "+N more" badge when exceeding 12.
class SugarCubeWidget extends StatelessWidget {
  final double teaspoons;
  final Color activeColor;

  const SugarCubeWidget({
    super.key,
    required this.teaspoons,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final fullCubes = teaspoons.floor();
    final remainder = teaspoons - fullCubes;

    // Cap displayed visual cubes at 12
    final displayFull = fullCubes > 12 ? 12 : fullCubes;
    final hasOverflow = fullCubes > 12;

    // Only render cubes when the sugar is 1 teaspoon or more.
    // For small amounts (< 1 tsp), omit the single fraction cube icon.
    if (teaspoons < 1.0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (int i = 0; i < displayFull; i++) _buildFullCube(context),
            if (remainder >= 0.15 && !hasOverflow) _buildPartialCube(context, remainder),
            if (hasOverflow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: GlucioTheme.accentLime,
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
                child: Text(
                  '+${fullCubes - 12} more',
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFullCube(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GlucioTheme.inkBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: GlucioTheme.inkBlack,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(
            Icons.grain,
            size: 13,
            color: GlucioTheme.inkBlack,
          ),
        ),
      ),
    );
  }

  Widget _buildPartialCube(BuildContext context, double fraction) {
    final label = fraction >= 0.75
        ? '¾'
        : fraction >= 0.4
            ? '½'
            : '¼';

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GlucioTheme.inkBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: GlucioTheme.inkBlack,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: GlucioTheme.fontBody,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: GlucioTheme.inkBlack,
          ),
        ),
      ),
    );
  }
}
