import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/sugar_swap.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../data/models/product.dart';
import '../../../../data/repositories/product_repository.dart';

/// Neo-Brutalist card displaying lower-sugar alternatives in the same category.
class SmarterSwapsCard extends ConsumerWidget {
  final Product product;
  final ValueChanged<Product> onSelectSwap;

  const SmarterSwapsCard({
    super.key,
    required this.product,
    required this.onSelectSwap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapsAsync = ref.watch(lowerSugarSwapsProvider(product));

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: GlucioTheme.cardDecoration(
        surface: GlucioTheme.cardCream,
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: GlucioTheme.inkBlack,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Smarter Swaps',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontDisplay,
                      fontSize: 20,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GlucioTheme.accentLime,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                ),
                child: const Text(
                  'Lower Sugar',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Healthier options in ${product.category} with significantly less sugar.',
            style: const TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 14),

          // Swaps Content
          swapsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: GlucioTheme.inkBlack),
              ),
            ),
            error: (err, _) => Text(
              'Could not load alternatives: $err',
              style: const TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
            data: (swaps) {
              if (swaps.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '⭐',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          product.sugarPer100 != null && product.sugarPer100! <= 5.0
                              ? 'Great choice! This is already one of the lowest-sugar choices in ${product.category}.'
                              : 'No lower-sugar alternatives found in this category yet.',
                          style: const TextStyle(
                            fontFamily: GlucioTheme.fontBody,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: GlucioTheme.inkBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: swaps.map((swap) => _buildSwapItem(context, swap)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwapItem(BuildContext context, SugarSwap swap) {
    final alt = swap.swapProduct;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: GlucioTheme.bgCream,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onSelectSwap(alt),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alt.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: GlucioTheme.inkBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${alt.brand} • ${alt.sugarPer100?.toStringAsFixed(1) ?? "?"}g sugar / 100g',
                        style: const TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Sugar savings badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GlucioTheme.levelLow,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: GlucioTheme.inkBlack, width: 1),
                        ),
                        child: Text(
                          swap.savingsDescription,
                          style: const TextStyle(
                            fontFamily: GlucioTheme.fontBody,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: GlucioTheme.cardCream,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: GlucioTheme.inkBlack,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
