import 'package:flutter/material.dart';
import '../../../../core/utils/sugar_calculator.dart';
import '../../../data/models/product.dart';
import 'widgets/sugar_cube_widget.dart';
import 'widgets/sugar_progress_bar.dart';

/// Screen displaying the complete sugar breakdown and cube visualizer for a scanned product.
class ProductResultScreen extends StatefulWidget {
  final Product product;

  const ProductResultScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductResultScreen> createState() => _ProductResultScreenState();
}

class _ProductResultScreenState extends State<ProductResultScreen> {
  // 0 = Per Serving, 1 = Entire Pack
  int _selectedPortionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isServing = _selectedPortionIndex == 0;

    final currentGrams = isServing ? p.servingSugarG : p.packSugarG;
    final currentTeaspoons = isServing ? p.servingTeaspoons : p.packTeaspoons;
    final currentPercent = isServing ? p.servingDailyPercent : p.packDailyPercent;
    final portionLabel = isServing
        ? 'Per Serving (${p.servingSizeG.toStringAsFixed(0)}g)'
        : 'Whole Pack (${p.packSizeG.toStringAsFixed(0)}g)';

    final severityColor = SugarCalculator.getSeverityColor(currentPercent);

    return Scaffold(
      appBar: AppBar(
        title: Text(p.brand.isNotEmpty ? p.brand : 'Glucio Sugar Scan'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Name & Category
            Text(
              p.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Barcode: ${p.barcode}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Portion Toggle: Serving vs Entire Pack
            SegmentedButton<int>(
              segments: [
                ButtonSegment<int>(
                  value: 0,
                  label: Text('Per Serving (${p.servingSizeG.toStringAsFixed(0)}g)'),
                  icon: const Icon(Icons.restaurant_menu),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text('Entire Pack (${p.packSizeG.toStringAsFixed(0)}g)'),
                  icon: const Icon(Icons.inventory_2_outlined),
                ),
              ],
              selected: {_selectedPortionIndex},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedPortionIndex = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 20),

            // Hero Sugar Visualizer Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: severityColor.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    portionLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        SugarCalculator.formatTeaspoons(currentTeaspoons),
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          color: severityColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'teaspoons',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: severityColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '(${currentGrams.toStringAsFixed(1)} grams total sugar)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Visual Sugar Cubes
                  SugarCubeWidget(
                    teaspoons: currentTeaspoons,
                    activeColor: severityColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Daily Limit Progress Bar
            SugarProgressBar(sugarGrams: currentGrams),
            const SizedBox(height: 16),

            // Hidden Sugar Warning Card (if applicable)
            if (p.hasHiddenSugar) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFE65100),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hidden Sugar Alert',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFFE65100),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This item belongs to "${p.category}", but contains ${p.sugarPer100g.toStringAsFixed(1)}g of sugar per 100g. Hidden sugars are common in savory snacks and sauces!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.brown.shade800,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Nutrition Facts Card
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Label Details',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildNutritionRow('Total Sugar (per 100g)', '${p.sugarPer100g.toStringAsFixed(1)} g'),
                    _buildNutritionRow(
                      'Added Sugar (per 100g)',
                      p.addedSugarPer100g != null
                          ? '${p.addedSugarPer100g!.toStringAsFixed(1)} g'
                          : 'Not declared on pack',
                    ),
                    _buildNutritionRow('Pack Size', '${p.packSizeG.toStringAsFixed(0)} g'),
                    _buildNutritionRow('Serving Size', '${p.servingSizeG.toStringAsFixed(0)} g'),
                    _buildNutritionRow(
                      'Data Source',
                      p.source == 'seed-unverified'
                          ? 'Seed Catalog (Unverified)'
                          : p.source,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Another Product'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
