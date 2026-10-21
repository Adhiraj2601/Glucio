import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../data/models/product_alert_verdict.dart';

/// Neo-Brutalist Alert Banner displayed right below the Sugar Hero when user preferences are evaluated.
class PersonalPreferencesAlertBanner extends StatelessWidget {
  final ProductAlertVerdict verdict;
  final VoidCallback? onSettingsTapped;

  const PersonalPreferencesAlertBanner({
    super.key,
    required this.verdict,
    this.onSettingsTapped,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (verdict.status) {
      case ProductAlertStatus.violates:
        if (verdict.isMandatoryViolation) {
          bg = GlucioTheme.levelHigh;
          fg = Colors.white;
          icon = Icons.error_rounded;
        } else {
          bg = GlucioTheme.levelMedium;
          fg = GlucioTheme.inkBlack;
          icon = Icons.warning_amber_rounded;
        }
        break;
      case ProductAlertStatus.matches:
        bg = GlucioTheme.levelLow;
        fg = Colors.white;
        icon = Icons.check_circle_rounded;
        break;
      case ProductAlertStatus.unknown:
        bg = const Color(0xFFE2DDD2);
        fg = GlucioTheme.inkBlack;
        icon = Icons.help_outline_rounded;
        break;
    }

    final reason = verdict.violations.isNotEmpty
        ? verdict.violations.join(' • ')
        : verdict.summary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
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
      child: Row(
        children: [
          Icon(icon, color: fg, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  verdict.isMandatoryViolation
                      ? 'NOT FOR YOU'
                      : (verdict.status == ProductAlertStatus.matches
                          ? 'PREFERENCES MATCH'
                          : 'DIETARY NOTICE'),
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontDisplay,
                    fontSize: 12,
                    letterSpacing: 0.5,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
          if (onSettingsTapped != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSettingsTapped,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GlucioTheme.cardCream,
                  shape: BoxShape.circle,
                  border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 14,
                  color: GlucioTheme.inkBlack,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
