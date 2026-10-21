import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../core/utils/product_alerts_engine.dart';
import '../../../../core/utils/sugar_calculator.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_alert_verdict.dart';
import '../../../data/models/user_preferences.dart';
import '../../../data/repositories/product_repository.dart';
import '../../product/presentation/product_result_screen.dart';
import '../../product/presentation/widgets/product_image_gallery_modal.dart';
import '../../scan/presentation/scanner_screen.dart';

/// Available sorting and ranking criteria for comparing foods side-by-side.
enum CompareSortCriterion {
  sugar('Lowest Sugar'),
  nutriScore('Best Nutri-Score'),
  nova('Least Processed (NOVA)'),
  calories('Lowest Calories'),
  salt('Lowest Salt'),
  fat('Lowest Fat');

  final String label;
  const CompareSortCriterion(this.label);
}

/// Screen presenting 2 to 4 products in a horizontally scrollable Neo-Brutalist comparison table.
class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  CompareSortCriterion _sortCriterion = CompareSortCriterion.sugar;

  List<Product> _sortProducts(List<Product> products) {
    final list = List<Product>.from(products);

    switch (_sortCriterion) {
      case CompareSortCriterion.sugar:
        list.sort((a, b) {
          final sA = a.sugarPer100 ?? 999.0;
          final sB = b.sugarPer100 ?? 999.0;
          return sA.compareTo(sB);
        });
        break;
      case CompareSortCriterion.nutriScore:
        list.sort((a, b) {
          final gA = a.nutriScoreGrade?.toLowerCase() ?? 'z';
          final gB = b.nutriScoreGrade?.toLowerCase() ?? 'z';
          return gA.compareTo(gB);
        });
        break;
      case CompareSortCriterion.nova:
        list.sort((a, b) {
          final nA = a.novaGroup ?? 99;
          final nB = b.novaGroup ?? 99;
          return nA.compareTo(nB);
        });
        break;
      case CompareSortCriterion.calories:
        list.sort((a, b) {
          final cA = a.details?.fullNutriments?.energyKcal100g ?? 9999.0;
          final cB = b.details?.fullNutriments?.energyKcal100g ?? 9999.0;
          return cA.compareTo(cB);
        });
        break;
      case CompareSortCriterion.salt:
        list.sort((a, b) {
          final sA = a.details?.fullNutriments?.salt100g ?? 999.0;
          final sB = b.details?.fullNutriments?.salt100g ?? 999.0;
          return sA.compareTo(sB);
        });
        break;
      case CompareSortCriterion.fat:
        list.sort((a, b) {
          final fA = a.details?.fullNutriments?.fat100g ?? 999.0;
          final fB = b.details?.fullNutriments?.fat100g ?? 999.0;
          return fA.compareTo(fB);
        });
        break;
    }

    return list;
  }

  String _buildRankReason(Product p, int rank, int total) {
    switch (_sortCriterion) {
      case CompareSortCriterion.sugar:
        final s = p.sugarPer100 != null ? '${p.sugarPer100!.toStringAsFixed(1)}g sugar' : 'Unknown sugar';
        return '#$rank • $s / 100g';
      case CompareSortCriterion.nutriScore:
        final g = p.nutriScoreGrade?.toUpperCase() ?? 'Not computed';
        return '#$rank • Nutri-Score $g';
      case CompareSortCriterion.nova:
        final n = p.novaGroup != null ? 'NOVA ${p.novaGroup}' : 'Not computed';
        return '#$rank • $n';
      case CompareSortCriterion.calories:
        final cal = p.details?.fullNutriments?.energyKcal100g;
        return '#$rank • ${cal != null ? "${cal.toStringAsFixed(0)} kcal" : "Calories unknown"}';
      case CompareSortCriterion.salt:
        final salt = p.details?.fullNutriments?.salt100g;
        return '#$rank • ${salt != null ? "${salt.toStringAsFixed(2)}g salt" : "Salt unknown"}';
      case CompareSortCriterion.fat:
        final fat = p.details?.fullNutriments?.fat100g;
        return '#$rank • ${fat != null ? "${fat.toStringAsFixed(1)}g fat" : "Fat unknown"}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productCompareProvider);
    final sortedProducts = _sortProducts(products);
    final prefsAsync = ref.watch(userPreferencesProvider);
    final userPrefs = prefsAsync.value ?? UserPreferences.defaults();

    return Scaffold(
      backgroundColor: GlucioTheme.bgCream,
      appBar: AppBar(
        title: const Text(
          'Compare Foods',
          style: TextStyle(
            fontFamily: GlucioTheme.fontDisplay,
            fontSize: 22,
            color: GlucioTheme.inkBlack,
          ),
        ),
        elevation: 0,
        backgroundColor: GlucioTheme.bgCream,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GlucioTheme.inkBlack),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (products.isNotEmpty) ...[
            IconButton(
              tooltip: 'Clear All',
              icon: const Icon(Icons.delete_sweep_rounded, color: GlucioTheme.inkBlack),
              onPressed: () {
                ref.read(productCompareProvider.notifier).clear();
              },
            ),
          ],
        ],
      ),
      body: products.isEmpty
          ? _buildEmptyState(context)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Control bar: Ranking selector & counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: GlucioTheme.cardCream,
                    border: Border(
                      bottom: BorderSide(color: GlucioTheme.inkBlack, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sort_rounded, size: 20, color: GlucioTheme.inkBlack),
                      const SizedBox(width: 8),
                      const Text(
                        'Rank by:',
                        style: TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: GlucioTheme.inkBlack,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<CompareSortCriterion>(
                              value: _sortCriterion,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: GlucioTheme.inkBlack),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _sortCriterion = val);
                                }
                              },
                              items: CompareSortCriterion.values.map((crit) {
                                return DropdownMenuItem(
                                  value: crit,
                                  child: Text(
                                    crit.label,
                                    style: const TextStyle(
                                      fontFamily: GlucioTheme.fontBody,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: GlucioTheme.inkBlack,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: GlucioTheme.accentLime,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                        ),
                        child: Text(
                          '${products.length}/4',
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
                ),

                // Table Horizontal Scroll
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: sortedProducts.length + (sortedProducts.length < 4 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < sortedProducts.length) {
                        return _buildProductColumn(
                          context,
                          sortedProducts[index],
                          index + 1,
                          sortedProducts,
                          userPrefs,
                        );
                      } else {
                        return _buildAddProductSlot(context);
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: GlucioTheme.accentLime,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: GlucioTheme.inkBlack,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.compare_arrows_rounded,
                size: 38,
                color: GlucioTheme.inkBlack,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Foods to Compare',
              style: TextStyle(
                fontFamily: GlucioTheme.fontDisplay,
                fontSize: 22,
                color: GlucioTheme.inkBlack,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add 2 to 4 products to compare sugar, Nutri-Score, NOVA, and allergens side-by-side.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 13,
                color: Colors.black54,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScannerScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: GlucioTheme.primaryGreen,
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
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Scan Food to Add',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProductSlot(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: GlucioTheme.cardCream.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GlucioTheme.inkBlack.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ScannerScreen()),
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 36, color: GlucioTheme.inkBlack),
                SizedBox(height: 10),
                Text(
                  '+ Add Product',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontDisplay,
                    fontSize: 14,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Scan another food',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductColumn(
    BuildContext context,
    Product p,
    int rank,
    List<Product> allInCompare,
    UserPreferences userPrefs,
  ) {
    final sugar = p.sugarPer100;
    final tsp = sugar != null ? sugar / 4.0 : null;
    final details = p.details;
    final nutriments = details?.fullNutriments;

    // Determine Best / Worst relative to all products in compare
    final allSugars = allInCompare.map((item) => item.sugarPer100).whereType<double>().toList();
    final isLowestSugar = allSugars.length > 1 && sugar != null && sugar == allSugars.reduce((a, b) => a < b ? a : b);
    final isHighestSugar = allSugars.length > 1 && sugar != null && sugar == allSugars.reduce((a, b) => a > b ? a : b);

    final alertVerdict = ProductAlertsEngine.evaluate(
      preferences: userPrefs,
      product: p,
      details: details,
    );

    final thumbUrl = details?.imageUrls.frontSmall ?? details?.imageUrls.front;

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 14),
      decoration: GlucioTheme.cardDecoration(
        surface: GlucioTheme.cardCream,
        radius: 18,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Close Button + Rank Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: rank == 1 ? GlucioTheme.accentLime : GlucioTheme.inkBlack,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                    ),
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontDisplay,
                        fontSize: 12,
                        color: rank == 1 ? GlucioTheme.inkBlack : Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(productCompareProvider.notifier).removeProduct(p.barcode);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                      ),
                      child: const Icon(Icons.close_rounded, size: 14, color: GlucioTheme.inkBlack),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Thumbnail Image
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (details?.imageUrls != null && details!.imageUrls.hasAnyImage) {
                      ProductImageGalleryModal.show(context, details.imageUrls, p.name);
                    }
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                    clipBehavior: Clip.antiAlias,
                    child: thumbUrl != null
                        ? Image.network(
                            thumbUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.fastfood_rounded, color: GlucioTheme.inkBlack),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.fastfood_rounded, color: GlucioTheme.inkBlack),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Name & Brand
              Text(
                p.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: GlucioTheme.fontDisplay,
                  fontSize: 14,
                  color: GlucioTheme.inkBlack,
                ),
              ),
              if (p.brand.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  p.brand,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Why this rank line
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rank == 1
                      ? GlucioTheme.levelLow.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: rank == 1 ? GlucioTheme.levelLow : Colors.black26,
                    width: 1,
                  ),
                ),
                child: Text(
                  _buildRankReason(p, rank, allInCompare.length),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: rank == 1 ? GlucioTheme.levelLow : GlucioTheme.inkBlack,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Row 1: Sugar Hero Box
              _buildSugarCompareBox(sugar, tsp, isLowestSugar, isHighestSugar),
              const SizedBox(height: 10),

              // Row 2: Nutri-Score
              _buildMetricRow(
                'Nutri-Score',
                details?.nutriScoreGrade?.toUpperCase() ?? 'Not computed',
                badgeColor: _getNutriScoreColor(details?.nutriScoreGrade),
              ),
              const SizedBox(height: 8),

              // Row 3: NOVA Group
              _buildMetricRow(
                'NOVA Group',
                details?.novaGroup != null ? 'NOVA ${details!.novaGroup}' : 'Not computed',
                badgeColor: _getNovaColor(details?.novaGroup),
              ),
              const SizedBox(height: 8),

              // Row 4: Calories
              _buildMetricRow(
                'Calories',
                nutriments?.energyKcal100g != null
                    ? '${nutriments!.energyKcal100g!.toStringAsFixed(0)} kcal'
                    : 'Not declared',
              ),
              const SizedBox(height: 8),

              // Row 5: Salt
              _buildMetricRow(
                'Salt',
                nutriments?.salt100g != null
                    ? '${nutriments!.salt100g!.toStringAsFixed(2)} g'
                    : 'Not declared',
              ),
              const SizedBox(height: 8),

              // Row 6: Total Fat
              _buildMetricRow(
                'Total Fat',
                nutriments?.fat100g != null
                    ? '${nutriments!.fat100g!.toStringAsFixed(1)} g'
                    : 'Not declared',
              ),
              const SizedBox(height: 8),

              // Row 7: Saturated Fat
              _buildMetricRow(
                'Sat Fat',
                nutriments?.saturatedFat100g != null
                    ? '${nutriments!.saturatedFat100g!.toStringAsFixed(1)} g'
                    : 'Not declared',
              ),
              const SizedBox(height: 8),

              // Row 8: Additives Count
              _buildMetricRow(
                'Additives',
                details?.additiveTags.isNotEmpty == true
                    ? '${details!.additiveTags.length} detected'
                    : 'None detected',
                isWarning: (details?.additiveTags.length ?? 0) >= 3,
              ),
              const SizedBox(height: 8),

              // Row 9: Dietary & Preferences Verdict
              _buildAlertVerdictChip(alertVerdict),
              const SizedBox(height: 8),

              // Row 10: Eco-Score
              _buildMetricRow(
                'Eco-Score',
                details?.ecoScoreGrade?.toUpperCase() ?? 'Not computed',
              ),
              const SizedBox(height: 14),

              // View Full Result Button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductResultScreen(product: p),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: GlucioTheme.accentLime,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      'View Product',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: GlucioTheme.inkBlack,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSugarCompareBox(
    double? sugar,
    double? tsp,
    bool isLowest,
    bool isHighest,
  ) {
    Color borderColor = GlucioTheme.inkBlack;
    IconData? indicatorIcon;
    Color indicatorColor = GlucioTheme.inkBlack;
    String? indicatorLabel;

    if (isLowest) {
      borderColor = GlucioTheme.levelLow;
      indicatorIcon = Icons.thumb_up_alt_rounded;
      indicatorColor = GlucioTheme.levelLow;
      indicatorLabel = 'Lowest Sugar';
    } else if (isHighest) {
      borderColor = GlucioTheme.levelHigh;
      indicatorIcon = Icons.warning_amber_rounded;
      indicatorColor = GlucioTheme.levelHigh;
      indicatorLabel = 'Highest Sugar';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isLowest || isHighest ? 2.5 : 1.5),
        boxShadow: const [
          BoxShadow(
            color: GlucioTheme.inkBlack,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'SUGAR (HERO)',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontDisplay,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
              ),
              if (indicatorIcon != null) ...[
                const SizedBox(width: 4),
                Icon(indicatorIcon, size: 16, color: indicatorColor),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sugar != null ? '${sugar.toStringAsFixed(1)}g / 100g' : 'Sugar unknown',
            style: const TextStyle(
              fontFamily: GlucioTheme.fontDisplay,
              fontSize: 16,
              color: GlucioTheme.inkBlack,
            ),
          ),
          if (tsp != null) ...[
            const SizedBox(height: 2),
            Text(
              SugarCalculator.formatTeaspoonsPlain(tsp),
              style: const TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
          if (indicatorLabel != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: indicatorColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                indicatorLabel,
                style: TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: indicatorColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value, {
    Color? badgeColor,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWarning ? GlucioTheme.levelHigh : GlucioTheme.inkBlack,
          width: isWarning ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: badgeColor != null
                  ? BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: GlucioTheme.inkBlack, width: 1),
                    )
                  : null,
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: badgeColor != null ? Colors.white : GlucioTheme.inkBlack,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertVerdictChip(ProductAlertVerdict verdict) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (verdict.status) {
      case ProductAlertStatus.violates:
        bg = GlucioTheme.levelHigh.withValues(alpha: 0.15);
        fg = GlucioTheme.levelHigh;
        icon = Icons.warning_amber_rounded;
        label = verdict.isMandatoryViolation ? 'Not for you' : 'Dietary notice';
        break;
      case ProductAlertStatus.matches:
        bg = GlucioTheme.levelLow.withValues(alpha: 0.15);
        fg = GlucioTheme.levelLow;
        icon = Icons.check_circle_outline_rounded;
        label = 'Matches diet';
        break;
      case ProductAlertStatus.unknown:
        bg = const Color(0xFFE2DDD2);
        fg = GlucioTheme.inkBlack;
        icon = Icons.help_outline_rounded;
        label = "Can't verify";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNutriScoreColor(String? grade) {
    switch (grade?.toLowerCase()) {
      case 'a':
        return GlucioTheme.nutriScoreA;
      case 'b':
        return GlucioTheme.nutriScoreB;
      case 'c':
        return GlucioTheme.nutriScoreC;
      case 'd':
        return GlucioTheme.nutriScoreD;
      case 'e':
        return GlucioTheme.nutriScoreE;
      default:
        return const Color(0xFF888888);
    }
  }

  Color _getNovaColor(int? group) {
    switch (group) {
      case 1:
        return GlucioTheme.nova1;
      case 2:
        return GlucioTheme.nova2;
      case 3:
        return GlucioTheme.nova3;
      case 4:
        return GlucioTheme.nova4;
      default:
        return const Color(0xFF888888);
    }
  }
}
