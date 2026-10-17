import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../core/utils/sugar_calculator.dart';
import '../../../data/models/portion.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import 'add_product_screen.dart';
import 'widgets/debug_trace_panel.dart';
import 'widgets/sugar_cube_widget.dart';
import 'widgets/sugar_progress_bar.dart';

/// Screen displaying the complete sugar breakdown and cube visualizer for a scanned product.
/// Built with Neo-brutalist styling: warm cream surfaces, 2px ink borders, and 4px hard shadows.
class ProductResultScreen extends StatefulWidget {
  final Product product;
  final LookupTrace? trace;

  const ProductResultScreen({
    super.key,
    required this.product,
    this.trace,
  });

  @override
  State<ProductResultScreen> createState() => _ProductResultScreenState();
}

class _ProductResultScreenState extends State<ProductResultScreen> {
  int _selectedPortionIndex = 0;
  int _multiplier = 1;

  @override
  void initState() {
    super.initState();
    // Default to the first portion (smallest unit or serving, whole pack is last)
    _selectedPortionIndex = 0;
    _multiplier = 1;
  }

  Portion _getCurrentPortion(Product p) {
    if (p.portions.isNotEmpty) {
      if (_selectedPortionIndex >= p.portions.length) {
        _selectedPortionIndex = 0;
      }
      return p.portions[_selectedPortionIndex];
    }
    // Fallback if portions list is empty
    return Portion(
      label: '1 serving (${p.servingSizeG.toStringAsFixed(0)}g)',
      amount: p.servingSizeG > 0 ? p.servingSizeG : 100.0,
      basis: 'g',
      kind: 'serving',
      source: 'label',
    );
  }

  String _buildHeroSentence(Product p, Portion portion, double sugarGrams, double teaspoons) {
    if (p.isVerifiedZero || (p.sugarPer100 != null && p.sugarPer100 == 0.0 && p.verified)) {
      if (_multiplier == 1) {
        return '${portion.label} has no sugar';
      } else {
        final totalAmount = (portion.amount * _multiplier).toStringAsFixed(0);
        return '$_multiplier × ${portion.label} ($totalAmount${portion.basis}) has no sugar';
      }
    }

    final sugarPhrase = SugarCalculator.formatTeaspoonsPlain(teaspoons, isVerifiedZero: p.isVerifiedZero);
    final categoryNoun = p.category.isNotEmpty ? p.category.toLowerCase() : 'product';

    if (_multiplier == 1) {
      return '${portion.label} of this $categoryNoun has $sugarPhrase of sugar';
    } else {
      final totalAmount = (portion.amount * _multiplier).toStringAsFixed(0);
      return '$_multiplier × ${portion.label} ($totalAmount${portion.basis}) of this $categoryNoun has $sugarPhrase of sugar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final hasSugar = p.hasSugarData;

    Portion? portion;
    double? currentSugarG;
    double? currentTeaspoons;
    double? currentPercent;
    Color severityColor = GlucioTheme.levelMissing;
    String heroSentence = '';

    if (hasSugar) {
      portion = _getCurrentPortion(p);
      final effectiveAmount = portion.amount * _multiplier;
      currentSugarG = (p.sugarPer100! * effectiveAmount) / 100.0;
      currentTeaspoons = currentSugarG / 4.0;
      currentPercent = SugarCalculator.toPercentDailyLimit(currentSugarG);
      severityColor = SugarCalculator.getSeverityColor(currentPercent);
      heroSentence = _buildHeroSentence(p, portion, currentSugarG, currentTeaspoons);
    }

    return Scaffold(
      backgroundColor: GlucioTheme.bgCream,
      appBar: AppBar(
        title: Text(
          p.brand.isNotEmpty ? p.brand : 'Glucio Sugar Scan',
          style: const TextStyle(
            fontFamily: GlucioTheme.fontDisplay,
            color: GlucioTheme.inkBlack,
            fontSize: 22,
          ),
        ),
        elevation: 0,
        backgroundColor: GlucioTheme.bgCream,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GlucioTheme.inkBlack),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: GlucioTheme.cardDecoration(
                surface: GlucioTheme.cardCream,
                radius: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontFamily: GlucioTheme.fontDisplay,
                                fontSize: 22,
                                color: GlucioTheme.inkBlack,
                              ),
                            ),
                            if (p.brand.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                p.brand,
                                style: const TextStyle(
                                  fontFamily: GlucioTheme.fontBody,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Category pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: GlucioTheme.pillDecoration(fill: GlucioTheme.accentLime),
                        child: Text(
                          p.category.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: GlucioTheme.fontBody,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: GlucioTheme.inkBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Barcode: ${p.barcode}',
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Missing Sugar State
            if (!hasSugar) ...[
              _buildMissingSugarCard(context, p),
              const SizedBox(height: 16),
            ] else ...[
              // Portion Selector Chips (Horizontally Scrollable)
              const Text(
                'Select Portion:',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: GlucioTheme.inkBlack,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < p.portions.length; i++)
                      _buildPortionChip(p.portions[i], i),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Multiplier Stepper: x1, x2, x3
              Row(
                children: [
                  const Text(
                    'Quantity / Servings:',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                  const Spacer(),
                  for (int mult in [1, 2, 3])
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _multiplier = mult;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _multiplier == mult
                                ? GlucioTheme.accentLime
                                : GlucioTheme.cardCream,
                            borderRadius: BorderRadius.circular(10),
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
                            'x$mult',
                            style: const TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Hero Sugar Sentence & Cubes Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: GlucioTheme.cardDecoration(
                  surface: GlucioTheme.cardCream,
                  radius: 20,
                ),
                child: Column(
                  children: [
                    // Sentence-first hero in chunky display font
                    Text(
                      heroSentence,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: GlucioTheme.fontDisplay,
                        fontSize: 22,
                        color: GlucioTheme.inkBlack,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '(${currentSugarG?.toStringAsFixed(1) ?? "0"} grams total sugar)',
                      style: const TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 2,
                      color: GlucioTheme.inkBlack,
                    ),
                    const SizedBox(height: 16),

                    // Visual Sugar Cubes (capped at 12 cubes + "+N more")
                    SugarCubeWidget(
                      teaspoons: currentTeaspoons ?? 0.0,
                      activeColor: severityColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Thick black-outlined Daily Limit Progress Bar
              SugarProgressBar(sugarGrams: currentSugarG),
              const SizedBox(height: 16),

              // Hidden Sugar Alert Banner (for savory foods with sugar)
              if (p.hasHiddenSugar) ...[
                _buildHiddenSugarAlert(p),
                const SizedBox(height: 16),
              ],
            ],

            // Collapsed "Label details" accordion for raw numbers
            _buildLabelDetailsAccordion(p),
            const SizedBox(height: 16),

            // Diagnostic Debug Trace Panel
            DebugTracePanel(trace: widget.trace),

            // Scan Another Product Button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: GlucioTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: GlucioTheme.inkBlack,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Scan Another Product',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPortionChip(Portion portion, int index) {
    final isSelected = _selectedPortionIndex == index;
    final isEstimate = portion.source == 'estimate';

    return Padding(
      padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPortionIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? GlucioTheme.accentLime : GlucioTheme.cardCream,
            borderRadius: BorderRadius.circular(14),
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
              Text(
                portion.label,
                style: const TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: GlucioTheme.inkBlack,
                ),
              ),
              if (isEstimate) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'about',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissingSugarCard(BuildContext context, Product p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: GlucioTheme.cardDecoration(
        surface: const Color(0xFFF0F0F0),
        radius: 20,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.help_outline_rounded,
            size: 48,
            color: Colors.black54,
          ),
          const SizedBox(height: 12),
          const Text(
            'Sugar data missing',
            style: TextStyle(
              fontFamily: GlucioTheme.fontDisplay,
              fontSize: 22,
              color: GlucioTheme.inkBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This product is in our database, but its exact sugar content was not listed on the label or Open Food Facts. We never assume missing data is zero!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontSize: 12,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddProductScreen(
                    initialBarcode: p.barcode,
                    initialName: p.name,
                    initialBrand: p.brand,
                    initialCategory: p.category,
                    initialPackSize: p.packSizeG,
                    initialServingSize: p.servingSizeG,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: GlucioTheme.accentLime,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: GlucioTheme.inkBlack,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: GlucioTheme.inkBlack, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Add or correct this product',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenSugarAlert(Product p) {
    final servingTsp = (p.sugarPer100 != null && p.servingSizeG > 0)
        ? (p.sugarPer100! * p.servingSizeG / 100.0) / 4.0
        : 0.0;
    final tspStr = SugarCalculator.formatTeaspoonsPlain(servingTsp);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlucioTheme.cardDecoration(
        surface: const Color(0xFFFFF3CD),
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: GlucioTheme.inkBlack, size: 24),
              SizedBox(width: 8),
              Text(
                'HIDDEN SUGAR ALERT',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontDisplay,
                  fontSize: 16,
                  color: GlucioTheme.inkBlack,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You wouldn\'t expect sugar in ${p.category}, but this has $tspStr per serving (${p.sugarPer100?.toStringAsFixed(1) ?? "?"}g per 100g). Hidden sugars are common in savory snacks and sauces!',
            style: const TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontSize: 12,
              color: GlucioTheme.inkBlack,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelDetailsAccordion(Product p) {
    return Container(
      decoration: GlucioTheme.cardDecoration(
        surface: GlucioTheme.cardCream,
        radius: 16,
      ),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          initiallyExpanded: false,
          title: const Text(
            'Label Details',
            style: TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: GlucioTheme.inkBlack,
            ),
          ),
          subtitle: const Text(
            'Per 100g/ml, added sugar, pack size & source',
            style: TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  _buildNutritionRow(
                    'Sugar Basis',
                    p.sugarBasis == 'per_100ml' ? 'per 100 ml' : 'per 100 g',
                  ),
                  _buildNutritionRow(
                    'Total Sugar',
                    p.sugarPer100 != null
                        ? '${p.sugarPer100!.toStringAsFixed(1)} g'
                        : 'Not declared on pack',
                  ),
                  _buildNutritionRow(
                    'Added Sugar',
                    p.addedSugarPer100g != null
                        ? '${p.addedSugarPer100g!.toStringAsFixed(1)} g'
                        : 'Not declared on pack',
                  ),
                  _buildNutritionRow('Pack Size', '${p.packSizeG.toStringAsFixed(0)} g'),
                  _buildNutritionRow('Serving Size', '${p.servingSizeG.toStringAsFixed(0)} g'),
                  _buildNutritionRow('Verified Label Checked', p.verified ? 'Yes' : 'No'),
                  _buildNutritionRow('Data Source', p.source),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: GlucioTheme.fontBody,
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: GlucioTheme.inkBlack,
            ),
          ),
        ],
      ),
    );
  }
}
