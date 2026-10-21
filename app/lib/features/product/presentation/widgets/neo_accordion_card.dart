import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';

/// Collapsible Neo-Brutalist accordion card with 2px ink border and hard 4px shadow.
class NeoAccordionCard extends StatefulWidget {
  final String title;
  final IconData? icon;
  final Widget? trailingBadge;
  final Widget child;
  final bool initiallyExpanded;

  const NeoAccordionCard({
    super.key,
    required this.title,
    this.icon,
    this.trailingBadge,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<NeoAccordionCard> createState() => _NeoAccordionCardState();
}

class _NeoAccordionCardState extends State<NeoAccordionCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: GlucioTheme.cardDecoration(
        surface: GlucioTheme.cardCream,
        radius: 18,
        withShadow: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20, color: GlucioTheme.inkBlack),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: GlucioTheme.fontDisplay,
                        fontSize: 16,
                        color: GlucioTheme.inkBlack,
                      ),
                    ),
                  ),
                  if (widget.trailingBadge != null) ...[
                    widget.trailingBadge!,
                    const SizedBox(width: 8),
                  ],
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: GlucioTheme.inkBlack,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Container(height: 2, color: GlucioTheme.inkBlack),
            Padding(
              padding: const EdgeInsets.all(18),
              child: widget.child,
            ),
          ],
        ],
      ),
    );
  }
}
