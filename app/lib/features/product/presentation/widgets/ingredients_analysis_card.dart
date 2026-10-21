import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../data/models/product_details.dart';

/// Neo-Brutalist card presenting ingredients text with highlighted allergens and dietary analysis chips.
class IngredientsAnalysisCard extends StatelessWidget {
  final String? ingredientsText;
  final List<String> allergenTags;
  final IngredientsAnalysis? analysis;

  const IngredientsAnalysisCard({
    super.key,
    this.ingredientsText,
    this.allergenTags = const [],
    this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    final text = ingredientsText?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Analysis chips row: Vegetarian | Vegan | Palm Oil
        if (analysis != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAnalysisChip('Vegetarian', analysis!.vegetarian),
              _buildAnalysisChip('Vegan', analysis!.vegan),
              _buildPalmOilChip(analysis!.palmOil),
            ],
          ),
          const SizedBox(height: 14),
        ],

        if (text != null && text.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GlucioTheme.cardCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
            ),
            child: _buildRichIngredients(text),
          ),
        ] else ...[
          const Text(
            'Full ingredients list not available for this item in the database.',
            style: TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnalysisChip(String label, String status) {
    Color bg = GlucioTheme.levelMissing;
    String text = '$label: ?';

    if (status == 'yes') {
      bg = GlucioTheme.levelLow;
      text = label;
    } else if (status == 'no') {
      bg = GlucioTheme.levelHigh;
      text = 'Non-$label';
    } else {
      bg = const Color(0xFFDCD8CE);
      text = '$label: Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: GlucioTheme.fontBody,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: (status == 'yes' || status == 'no') ? Colors.white : GlucioTheme.inkBlack,
        ),
      ),
    );
  }

  Widget _buildPalmOilChip(String status) {
    Color bg = GlucioTheme.levelMissing;
    String text = 'Palm oil: Unknown';

    if (status == 'no') {
      bg = GlucioTheme.levelLow;
      text = 'Palm Oil Free';
    } else if (status == 'yes') {
      bg = GlucioTheme.levelHigh;
      text = 'Contains Palm Oil';
    } else {
      bg = const Color(0xFFDCD8CE);
      text = 'Palm Oil: Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: GlucioTheme.fontBody,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: (status == 'yes' || status == 'no') ? Colors.white : GlucioTheme.inkBlack,
        ),
      ),
    );
  }

  Widget _buildRichIngredients(String fullText) {
    final cleanedTags = allergenTags
        .map((t) => t.toLowerCase().replaceAll('en:', '').trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (cleanedTags.isEmpty) {
      return Text(
        fullText,
        style: const TextStyle(
          fontFamily: GlucioTheme.fontBody,
          fontSize: 12,
          height: 1.5,
          color: GlucioTheme.inkBlack,
        ),
      );
    }

    // Split words and highlight allergens
    final words = fullText.split(' ');
    final spans = <TextSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final lowerWord = word.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final isAllergen = cleanedTags.any((t) => lowerWord.contains(t) || t.contains(lowerWord));

      spans.add(TextSpan(
        text: '$word ',
        style: TextStyle(
          fontFamily: GlucioTheme.fontBody,
          fontSize: 12,
          height: 1.5,
          fontWeight: isAllergen ? FontWeight.bold : FontWeight.normal,
          color: isAllergen ? GlucioTheme.levelHigh : GlucioTheme.inkBlack,
          decoration: isAllergen ? TextDecoration.underline : TextDecoration.none,
          decorationColor: GlucioTheme.levelHigh,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
