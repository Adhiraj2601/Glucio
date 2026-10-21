import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../core/utils/ean_checksum_validator.dart';
import '../../../../core/utils/sugar_calculator.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../product/presentation/add_product_screen.dart';
import '../../product/presentation/product_result_screen.dart';

/// Screen allowing users to discover and search food products across
/// local offline database and Open Food Facts with category filters.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounceTimer;

  bool _indiaOnly = true;
  String _selectedCategory = 'All';
  bool _isLoading = false;
  List<Product> _results = [];
  bool _hasSearched = false;

  final List<String> _categories = [
    'All',
    'Biscuits',
    'Beverages',
    'Snacks',
    'Cereals',
    'Sauces',
    'Dairy',
  ];

  final List<String> _quickSearches = [
    'Parle-G',
    'Thums Up',
    'Ketchup',
    'Bhujia',
    'Maggi',
    'Oats',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final repo = ref.read(offRepositoryProvider);
    final categoryFilter = _selectedCategory == 'All' ? null : _selectedCategory;

    final items = await repo.searchProducts(
      clean,
      indiaOnly: _indiaOnly,
      category: categoryFilter,
    );

    if (!mounted) return;

    setState(() {
      _results = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rawText = _searchCtrl.text.trim();
    final isBarcode = RegExp(r'^\d{8,14}$').hasMatch(rawText);
    final isChecksumValid = isBarcode && EanChecksumValidator.isValid(rawText);

    final compareList = ref.watch(productCompareProvider);

    return Scaffold(
      backgroundColor: GlucioTheme.bgCream,
      appBar: AppBar(
        title: const Text(
          'Search & Discover',
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                autofocus: false,
                style: const TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: GlucioTheme.inkBlack,
                ),
                decoration: InputDecoration(
                  hintText: 'Search products, brands, or barcode...',
                  hintStyle: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    color: Colors.black45,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: GlucioTheme.inkBlack),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: GlucioTheme.inkBlack),
                          onPressed: () {
                            _searchCtrl.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Filters: India Toggle + Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => _indiaOnly = !_indiaOnly);
                    _performSearch(_searchCtrl.text);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _indiaOnly
                          ? GlucioTheme.accentLime
                          : GlucioTheme.cardCream,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _indiaOnly ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 16,
                          color: GlucioTheme.inkBlack,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'India Only',
                          style: TextStyle(
                            fontFamily: GlucioTheme.fontBody,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: GlucioTheme.inkBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedCategory = cat);
                              _performSearch(_searchCtrl.text);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? GlucioTheme.inkBlack
                                    : GlucioTheme.cardCream,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: GlucioTheme.inkBlack, width: 1.5),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontFamily: GlucioTheme.fontBody,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.white : GlucioTheme.inkBlack,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Direct Barcode Lookup Notice if user entered digits
          if (isBarcode) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: GestureDetector(
                onTap: () async {
                  final repo = ref.read(productRepositoryProvider);
                  final p = await repo.getProductByBarcode(rawText);
                  if (!mounted) return;
                  if (p != null) {
                    Navigator.of(this.context).push(
                      MaterialPageRoute(
                          builder: (_) => ProductResultScreen(product: p)),
                    );
                  } else {
                    Navigator.of(this.context).push(
                      MaterialPageRoute(
                        builder: (_) => AddProductScreen(initialBarcode: rawText),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isChecksumValid
                        ? GlucioTheme.accentLime
                        : const Color(0xFFFFECC8),
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
                    children: [
                      const Icon(Icons.qr_code_scanner, color: GlucioTheme.inkBlack),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isChecksumValid
                                  ? 'Valid Barcode: $rawText'
                                  : 'Barcode format detected: $rawText',
                              style: const TextStyle(
                                fontFamily: GlucioTheme.fontDisplay,
                                fontSize: 13,
                                color: GlucioTheme.inkBlack,
                              ),
                            ),
                            const Text(
                              'Tap to lookup directly or add missing product',
                              style: TextStyle(
                                fontFamily: GlucioTheme.fontBody,
                                fontSize: 11,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: GlucioTheme.inkBlack),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Search Results or Empty Prompt
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: GlucioTheme.inkBlack),
                  )
                : _hasSearched
                    ? _buildResultsList(context, compareList)
                    : _buildInitialPrompt(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialPrompt(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POPULAR SEARCHES',
            style: TextStyle(
              fontFamily: GlucioTheme.fontDisplay,
              fontSize: 14,
              letterSpacing: 0.5,
              color: GlucioTheme.inkBlack,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSearches.map((term) {
              return GestureDetector(
                onTap: () {
                  _searchCtrl.text = term;
                  _performSearch(term);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: GlucioTheme.cardCream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
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
                      const Icon(Icons.history_rounded,
                          size: 14, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(
                        term,
                        style: const TextStyle(
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
            }).toList(),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: GlucioTheme.cardDecoration(
              surface: GlucioTheme.cardCream,
              radius: 16,
            ),
            child: const Row(
              children: [
                Icon(Icons.public_rounded,
                    color: GlucioTheme.inkBlack, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search over 280+ verified Indian seed foods offline, or connect to Open Food Facts worldwide catalog.',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, List<Product> compareList) {
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 48, color: Colors.black45),
              const SizedBox(height: 12),
              const Text(
                'No Products Found',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontDisplay,
                  fontSize: 20,
                  color: GlucioTheme.inkBlack,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try searching with a different brand, generic term, or scan the packaging barcode directly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddProductScreen(
                        initialBarcode: '',
                        initialName: _searchCtrl.text,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: GlucioTheme.accentLime,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                  ),
                  child: const Text(
                    '+ Add Missing Product',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final p = _results[index];
        final isInCompare = compareList.any((cp) => cp.barcode == p.barcode);
        final thumb = p.details?.imageUrls.frontSmall ?? p.details?.imageUrls.front;

        final sugarStr = p.sugarPer100 != null
            ? '${p.sugarPer100!.toStringAsFixed(1)}g sugar (${SugarCalculator.formatTeaspoonsPlain(p.sugarPer100! / 4.0)})'
            : 'Sugar not listed';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: GlucioTheme.cardDecoration(
            surface: GlucioTheme.cardCream,
            radius: 14,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductResultScreen(product: p),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Image thumbnail
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: thumb != null
                          ? Image.network(
                              thumb,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.fastfood_rounded, size: 24),
                            )
                          : const Icon(Icons.fastfood_rounded, size: 24),
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                              style: const TextStyle(
                                fontFamily: GlucioTheme.fontBody,
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            sugarStr,
                            style: const TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (p.nutriScoreGrade != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getNutriScoreColor(p.nutriScoreGrade),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: GlucioTheme.inkBlack, width: 1),
                                  ),
                                  child: Text(
                                    'NUTRI-SCORE ${p.nutriScoreGrade!.toUpperCase()}',
                                    style: const TextStyle(
                                      fontFamily: GlucioTheme.fontBody,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (p.novaGroup != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getNovaColor(p.novaGroup),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: GlucioTheme.inkBlack, width: 1),
                                  ),
                                  child: Text(
                                    'NOVA ${p.novaGroup}',
                                    style: const TextStyle(
                                      fontFamily: GlucioTheme.fontBody,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Compare toggle button
                    IconButton(
                      icon: Icon(
                        isInCompare
                            ? Icons.compare_arrows
                            : Icons.compare_arrows_outlined,
                        color: isInCompare
                            ? GlucioTheme.primaryGreen
                            : GlucioTheme.inkBlack,
                      ),
                      tooltip: isInCompare ? 'In Compare' : 'Add to Compare',
                      onPressed: () {
                        final notifier =
                            ref.read(productCompareProvider.notifier);
                        if (isInCompare) {
                          notifier.removeProduct(p.barcode);
                        } else {
                          notifier.addProduct(p);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
