import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../core/utils/additive_risk_lookup.dart';

/// Interactive Neo-Brutalist NOVA processing group badge (1 to 4).
class NovaBadge extends StatelessWidget {
  final int? group; // 1, 2, 3, 4
  final List<String> additiveTags;
  final VoidCallback? onTap;

  const NovaBadge({
    super.key,
    this.group,
    this.additiveTags = const [],
    this.onTap,
  });

  static Color _getGroupColor(int? g) {
    switch (g) {
      case 1:
        return GlucioTheme.nova1;
      case 2:
        return GlucioTheme.nova2;
      case 3:
        return GlucioTheme.nova3;
      case 4:
        return GlucioTheme.nova4;
      default:
        return GlucioTheme.levelMissing;
    }
  }

  static String _getGroupTitle(int? g) {
    switch (g) {
      case 1:
        return 'Unprocessed or minimally processed';
      case 2:
        return 'Processed culinary ingredients';
      case 3:
        return 'Processed foods';
      case 4:
        return 'Ultra-processed food and drink';
      default:
        return 'Not computed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidGroup = group != null && group! >= 1 && group! <= 4;

    if (!hasValidGroup) {
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
                'NOVA: Not computed',
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

    final color = _getGroupColor(group);

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
                  'FOOD PROCESSING',
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
                    group.toString(),
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontDisplay,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  group == 4 ? 'NOVA 4 (Ultra-processed)' : 'NOVA $group',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: group == 4 ? GlucioTheme.levelHigh : GlucioTheme.inkBlack,
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
      builder: (ctx) => _NovaBottomSheet(
        group: group,
        additiveTags: additiveTags,
      ),
    );
  }
}

class _NovaBottomSheet extends StatelessWidget {
  final int? group;
  final List<String> additiveTags;

  const _NovaBottomSheet({this.group, this.additiveTags = const []});

  @override
  Widget build(BuildContext context) {
    final color = NovaBadge._getGroupColor(group);
    final title = NovaBadge._getGroupTitle(group);

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
                      group?.toString() ?? '?',
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
                          'NOVA Group ${group ?? "?"}',
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
                child: Text(
                  _getGroupLongDescription(group),
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 12,
                    height: 1.4,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
              ),
              if (group == 4 && additiveTags.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'MARKERS OF ULTRA-PROCESSING IDENTIFIED',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontDisplay,
                    fontSize: 13,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: additiveTags.map((tag) {
                    final info = AdditiveRiskLookup.lookup(tag);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: GlucioTheme.cardCream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                      ),
                      child: Text(
                        '${info.code}: ${info.name}',
                        style: const TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: GlucioTheme.inkBlack,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'WHAT IS THE NOVA CLASSIFICATION?',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontDisplay,
                  fontSize: 13,
                  color: GlucioTheme.inkBlack,
                ),
              ),
              const SizedBox(height: 8),
              _buildNovaGuideItem(1, 'NOVA 1', 'Unprocessed foods (fruits, seeds, grains, milk)'),
              _buildNovaGuideItem(2, 'NOVA 2', 'Culinary ingredients (oils, butter, sugar, salt)'),
              _buildNovaGuideItem(3, 'NOVA 3', 'Processed foods (canned veg, simple cheeses, breads)'),
              _buildNovaGuideItem(4, 'NOVA 4', 'Ultra-processed formulations (flavorings, emulsifiers, dyes)'),
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
                        'NOVA classifies foods by degree of processing, complementing nutritional facts.',
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

  static String _getGroupLongDescription(int? g) {
    switch (g) {
      case 1:
        return 'Group 1 foods are obtained directly from plants or animals without industrial alteration, or minimally cleaned, dried, or pasteurized.';
      case 2:
        return 'Group 2 substances are extracted directly from group 1 foods or nature (e.g. oils, salt, sugar) used in domestic kitchens to prepare dishes.';
      case 3:
        return 'Group 3 products are simple foods made by adding oil, sugar, or salt to Group 1 foods (e.g. canned beans, artisanal bakery bread).';
      case 4:
        return 'Group 4 ultra-processed foods are industrial formulations typically containing 5+ ingredients not found in domestic culinary preparations, including dyes, artificial sweeteners, and emulsifiers.';
      default:
        return 'No processing data is available for this product in the Open Food Facts catalog.';
    }
  }

  Widget _buildNovaGuideItem(int num, String label, String desc) {
    final color = NovaBadge._getGroupColor(num);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: GlucioTheme.inkBlack, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              num.toString(),
              style: const TextStyle(
                fontFamily: GlucioTheme.fontDisplay,
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $desc',
              style: const TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 11,
                color: GlucioTheme.inkBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
