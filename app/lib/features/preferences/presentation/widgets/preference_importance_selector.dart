import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../data/models/user_preferences.dart';

/// Neo-Brutalist segmented control for selecting criterion importance:
/// Not important / Important / Very important / Mandatory.
class PreferenceImportanceSelector extends StatelessWidget {
  final PreferenceImportance selected;
  final ValueChanged<PreferenceImportance> onChanged;

  const PreferenceImportanceSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  Color _getActiveColor(PreferenceImportance level) {
    switch (level) {
      case PreferenceImportance.notImportant:
        return const Color(0xFFE0DDD5);
      case PreferenceImportance.important:
        return GlucioTheme.accentLime;
      case PreferenceImportance.veryImportant:
        return GlucioTheme.levelMedium;
      case PreferenceImportance.mandatory:
        return GlucioTheme.levelHigh;
    }
  }

  Color _getTextColor(PreferenceImportance level) {
    if (level == PreferenceImportance.mandatory) {
      return Colors.white;
    }
    return GlucioTheme.inkBlack;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: PreferenceImportance.values.map((importance) {
              final isSelected = selected == importance;
              final activeColor = _getActiveColor(importance);
              final textColor = isSelected
                  ? _getTextColor(importance)
                  : Colors.black54;

              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: GestureDetector(
                  onTap: () => onChanged(importance),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : GlucioTheme.cardCream,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: GlucioTheme.inkBlack,
                        width: isSelected ? 2 : 1.5,
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
                    child: Text(
                      importance.label,
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
