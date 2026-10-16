import 'package:flutter/material.dart';

/// Visual widget that renders sugar cubes for a given teaspoon count.
/// 1 sugar cube = 1 teaspoon = 4.0 grams.
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
    // Teaspoons mapped to cubes: full cubes + fractional remainder
    final fullCubes = teaspoons.floor();
    final remainder = teaspoons - fullCubes;

    // Cap displayed visual cubes at 24 to avoid screen overflow while showing "+X more"
    final displayFull = fullCubes > 20 ? 20 : fullCubes;
    final hasOverflow = fullCubes > 20;

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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${fullCubes - 20} more',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '1 Cube = 1 Teaspoon (4g)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
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
        border: Border.all(color: activeColor.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.2),
            offset: const Offset(2, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(
            Icons.grain,
            size: 14,
            color: activeColor,
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
        border: Border.all(
          color: activeColor.withValues(alpha: 0.5),
          width: 1.5,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: activeColor,
          ),
        ),
      ),
    );
  }
}
