import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../core/utils/sugar_calculator.dart';
import '../../../data/models/food_log_entry.dart';
import '../../../data/models/portion.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_alert_verdict.dart';
import '../../../data/models/user_preferences.dart';
import '../../../data/repositories/product_repository.dart';
import '../../log/presentation/providers/daily_tracker_providers.dart';
import '../../preferences/presentation/preferences_screen.dart';
import 'add_product_screen.dart';
import 'widgets/additives_card.dart';
import 'widgets/allergens_card.dart';
import 'widgets/debug_trace_panel.dart';
import 'widgets/ingredients_analysis_card.dart';
import 'widgets/labels_origins_card.dart';
import 'widgets/neo_accordion_card.dart';
import 'widgets/nutrition_facts_card.dart';
import 'widgets/packaging_card.dart';
import 'widgets/personal_preferences_alert_banner.dart';
import 'widgets/product_image_gallery_modal.dart';
import 'widgets/product_quality_row.dart';
import 'widgets/smarter_swaps_card.dart';
import 'widgets/sugar_cube_widget.dart';
import 'widgets/sugar_progress_bar.dart';

/// Screen displaying the complete sugar breakdown and cube visualizer for a scanned product,
/// extended with Open Food Facts nutritional quality assessment, label analysis, and dietary preferences.
/// Built with Neo-brutalist styling: warm cream surfaces, 2px ink borders, and 4px hard shadows.
class ProductResultScreen extends ConsumerStatefulWidget {
  final Product product;
  final LookupTrace? trace;

  const ProductResultScreen({
    super.key,
    required this.product,
    this.trace,
  });

  @override
  ConsumerState<ProductResultScreen> createState() => _ProductResultScreenState();
}

class _ProductResultScreenState extends ConsumerState<ProductResultScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedPortionIndex = 0;
  int _multiplier = 1;

  @override
  void initState() {
    super.initState();
    _selectedPortionIndex = 0;
    _multiplier = 1;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Portion _getCurrentPortion(Product p) {
    if (p.portions.isNotEmpty) {
      if (_selectedPortionIndex >= p.portions.length) {
        _selectedPortionIndex = 0;
      }
      return p.portions[_selectedPortionIndex];
    }
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

    if (_multiplier == 1) {
      return '${portion.label} has $sugarPhrase of sugar';
    } else {
      return '$_multiplier × ${portion.label} has $sugarPhrase of sugar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final hasSugar = p.hasSugarData;

    // Progressive OFF Enrichment & Dietary Alert
    final detailsAsync = ref.watch(productDetailsProvider(p.barcode));
    final details = detailsAsync.value ?? p.details;

    final alertsAsync = ref.watch(productAlertsProvider(p.barcode));
    final alertVerdict = alertsAsync.value;

    final prefsAsync = ref.watch(userPreferencesProvider);
    final userPrefs = prefsAsync.value;

    final compareList = ref.watch(productCompareProvider);
    final isInCompare = compareList.any((cp) => cp.barcode == p.barcode);

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

    final imageUrls = details?.imageUrls;
    final thumbUrl = imageUrls?.frontSmall ?? imageUrls?.front;
    final hasImages = imageUrls != null && imageUrls.hasAnyImage;

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
        actions: [
          IconButton(
            tooltip: isInCompare ? 'In Comparison (${compareList.length}/4)' : 'Add to Compare',
            icon: Icon(
              isInCompare ? Icons.compare_arrows : Icons.compare_arrows_outlined,
              color: isInCompare ? GlucioTheme.primaryGreen : GlucioTheme.inkBlack,
              size: 26,
            ),
            onPressed: () {
              final notifier = ref.read(productCompareProvider.notifier);
              if (isInCompare) {
                notifier.removeProduct(p.barcode);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Removed from product comparison'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                final added = notifier.addProduct(p);
                if (added) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${p.name} added to comparison (${compareList.length + 1}/4)'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comparison list full (max 4 products)'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Add or Correct Product Data',
            icon: const Icon(Icons.edit_note_rounded, color: GlucioTheme.inkBlack, size: 28),
            onPressed: () {
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
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
                      if (hasImages && thumbUrl != null) ...[
                        GestureDetector(
                          onTap: () {
                            ProductImageGalleryModal.show(
                              context,
                              imageUrls,
                              p.name,
                            );
                          },
                          child: Container(
                            width: 58,
                            height: 58,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  thumbUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.fastfood_rounded,
                                        color: GlucioTheme.inkBlack, size: 24),
                                  ),
                                ),
                                Positioned(
                                  right: 2,
                                  bottom: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: GlucioTheme.inkBlack,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.zoom_in_rounded,
                                        size: 10, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                            if (details?.quantity != null && details!.quantity!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                details.quantity!,
                                style: const TextStyle(
                                  fontFamily: GlucioTheme.fontBody,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: GlucioTheme.inkBlack,
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

            // Missing Sugar State vs Sugar Hero Breakdown
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
                        fontFamilyFallback: [GlucioTheme.fontBody, 'Roboto', 'sans-serif'],
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
                    // Only render divider and cubes when sugar is 1 teaspoon or more
                    if ((currentTeaspoons ?? 0.0) >= 1.0) ...[
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
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Thick black-outlined Daily Limit Progress Bar
              SugarProgressBar(
                sugarGrams: currentSugarG,
                sugarPer100: p.sugarPer100,
                isLiquid: p.sugarBasis.contains('ml'),
              ),
              const SizedBox(height: 16),

              // Hidden Sugar Alert Banner (for savory foods with sugar)
              if (p.hasHiddenSugar) ...[
                _buildHiddenSugarAlert(p),
                const SizedBox(height: 16),
              ],

              // Log This Food Button
              GestureDetector(
                onTap: () => _logCurrentPortion(p, portion!, currentSugarG),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: GlucioTheme.accentLime,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bookmark_add_rounded,
                        color: GlucioTheme.inkBlack,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentSugarG != null
                            ? 'LOG THIS FOOD (${currentSugarG.toStringAsFixed(1)}g sugar)'
                            : 'LOG THIS FOOD',
                        style: const TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: GlucioTheme.inkBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Personal Preferences Alert Banner (under the sugar hero)
            if (alertVerdict != null &&
                (alertVerdict.status != ProductAlertStatus.matches ||
                    (userPrefs?.criteria.values.any((c) =>
                            c.id != 'nutr_low_sugar' &&
                            c.importance != PreferenceImportance.notImportant) ??
                        false))) ...[
              PersonalPreferencesAlertBanner(
                verdict: alertVerdict,
                onSettingsTapped: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PreferencesScreen(),
                    ),
                  );
                },
              ),
            ],

            // Nutritional Quality Assessment Row (Nutri-Score, NOVA, Eco-Score, Nutrient Levels)
            ProductQualityRow(
              details: details,
              sugarGrams: currentSugarG,
              showEcoScore: details?.ecoScoreGrade != null,
              onSugarTapped: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            ),
            const SizedBox(height: 16),

            // Smarter Swaps (Lower-sugar alternatives in same category)
            SmarterSwapsCard(
              product: p,
              onSelectSwap: (swapProduct) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ProductResultScreen(product: swapProduct),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Collapsible Neo Accordion Cards
            // 1. Ingredients & Dietary Analysis Card
            NeoAccordionCard(
              title: 'Ingredients & Diet',
              icon: Icons.eco_outlined,
              child: IngredientsAnalysisCard(
                ingredientsText: details?.ingredientsText,
                allergenTags: details?.allergenTags ?? const [],
                analysis: details?.ingredientsAnalysis,
              ),
            ),

            // 2. Allergens & Traces Card
            NeoAccordionCard(
              title: 'Allergens & Traces',
              icon: Icons.warning_amber_rounded,
              trailingBadge: (details?.allergenTags.isNotEmpty ?? false)
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: GlucioTheme.levelHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${details!.allergenTags.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              child: AllergensCard(
                allergenTags: details?.allergenTags ?? const [],
                traceTags: details?.traceTags ?? const [],
              ),
            ),

            // 3. Nutrition Facts Card (100g vs Serving Toggle)
            NeoAccordionCard(
              title: 'Full Nutrition Facts',
              icon: Icons.table_chart_outlined,
              child: NutritionFactsCard(
                nutriments: details?.fullNutriments,
                levels: details?.nutrientLevels,
                servingDescription: portion?.label,
              ),
            ),

            // 4. Additives & Processing Card
            NeoAccordionCard(
              title: 'Additives & Processing',
              icon: Icons.science_outlined,
              trailingBadge: (details?.additiveTags.isNotEmpty ?? false)
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: GlucioTheme.levelMedium,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${details!.additiveTags.length}',
                        style: const TextStyle(
                          color: GlucioTheme.inkBlack,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              child: AdditivesCard(
                additiveTags: details?.additiveTags ?? const [],
              ),
            ),

            // 5. Certifications, Labels & Origins Card
            NeoAccordionCard(
              title: 'Labels & Origins',
              icon: Icons.verified_outlined,
              child: LabelsOriginsCard(
                labelTags: details?.labelTags ?? const [],
                origins: details?.origins,
              ),
            ),

            // 6. Packaging & Recycling Card
            NeoAccordionCard(
              title: 'Packaging & Recycling',
              icon: Icons.inventory_2_outlined,
              child: PackagingCard(
                packaging: details?.packaging,
                packagingTags: details?.packagingTags ?? const [],
              ),
            ),

            // 7. Technical Label Details
            NeoAccordionCard(
              title: 'Technical Label Details',
              icon: Icons.info_outline,
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

            // Open Food Facts Community Contribution & Attribution Card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: GlucioTheme.cardDecoration(
                surface: GlucioTheme.cardCream,
                radius: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.volunteer_activism_outlined,
                          color: GlucioTheme.inkBlack, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Help Improve Glucio',
                        style: TextStyle(
                          fontFamily: GlucioTheme.fontDisplay,
                          fontSize: 16,
                          color: GlucioTheme.inkBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Notice an error or missing information? Add or correct product details to enrich Open Food Facts for everyone.',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: GlucioTheme.accentLime,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: GlucioTheme.inkBlack,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Contribute / Edit Product',
                          style: TextStyle(
                            fontFamily: GlucioTheme.fontBody,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: GlucioTheme.inkBlack,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Data from Open Food Facts, ODbL; images CC-BY-SA',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, color: GlucioTheme.inkBlack, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Add or correct this product',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: GlucioTheme.inkBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _logCurrentPortion(p, _getCurrentPortion(p), null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: GlucioTheme.cardCream,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_add_outlined, color: GlucioTheme.inkBlack, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Log Food Anyway (Unknown Sugar)',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: GlucioTheme.inkBlack,
                      ),
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

  Future<void> _logCurrentPortion(
    Product p,
    Portion portion,
    double? currentSugarG,
  ) async {
    final entry = FoodLogEntry(
      barcode: p.barcode,
      name: p.name,
      brand: p.brand,
      portionLabel: _multiplier > 1
          ? '${portion.label} (x$_multiplier)'
          : portion.label,
      portionAmount: portion.amount * _multiplier,
      portionBasis: p.sugarBasis.contains('ml') ? 'ml' : 'g',
      sugarGrams: currentSugarG,
      loggedAt: DateTime.now(),
    );

    await ref.read(todayFoodLogsProvider.notifier).addLog(entry);

    if (!mounted) return;

    final limit = ref.read(dailyLimitProvider).value ?? 25.0;
    final totalConsumed = ref.read(todayTotalSugarProvider);
    final remaining = limit - totalConsumed;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: GlucioTheme.inkBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: GlucioTheme.accentLime, width: 1.5),
        ),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: GlucioTheme.accentLime, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                currentSugarG != null
                    ? 'Logged! ${totalConsumed.toStringAsFixed(1)}g / ${limit.toStringAsFixed(0)}g consumed today (${remaining >= 0 ? "${remaining.toStringAsFixed(1)}g left" : "${(-remaining).toStringAsFixed(1)}g over"})'
                    : 'Logged to tracker (Sugar unknown)',
                style: const TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
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
