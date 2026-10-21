import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../core/utils/nutrition_label_ocr_parser.dart';
import '../../../../core/utils/portion_builder.dart';
import '../../../../data/models/product.dart';
import '../../../../data/repositories/product_repository.dart';

/// Neo-Brutalist bottom sheet allowing users to add or correct nutrition facts for a product.
///
/// Supports on-device OCR via Google ML Kit to automatically extract sugar and serving size from label photos.
class ProductCorrectionSheet extends ConsumerStatefulWidget {
  final String barcode;
  final Product? initialProduct;
  final ValueChanged<Product> onProductSaved;

  const ProductCorrectionSheet({
    super.key,
    required this.barcode,
    this.initialProduct,
    required this.onProductSaved,
  });

  static Future<void> show({
    required BuildContext context,
    required String barcode,
    Product? initialProduct,
    required ValueChanged<Product> onProductSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductCorrectionSheet(
        barcode: barcode,
        initialProduct: initialProduct,
        onProductSaved: onProductSaved,
      ),
    );
  }

  @override
  ConsumerState<ProductCorrectionSheet> createState() => _ProductCorrectionSheetState();
}

class _ProductCorrectionSheetState extends ConsumerState<ProductCorrectionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _packSizeController;
  late TextEditingController _servingSizeController;
  late TextEditingController _sugarController;
  late TextEditingController _addedSugarController;

  late String _selectedCategory;
  bool _isOcrProcessing = false;
  String? _ocrStatusMessage;

  final List<String> _categories = [
    'biscuits',
    'beverage',
    'namkeen',
    'instant noodles',
    'sauces',
    'confectionery',
    'chips',
    'dairy',
    'yogurt',
    'bread',
    'cereals',
    'health drink',
    'sweets',
    'snacks',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    _nameController = TextEditingController(text: p?.name ?? '');
    _brandController = TextEditingController(text: p?.brand ?? '');
    _packSizeController = TextEditingController(
      text: p != null ? p.packSize.toStringAsFixed(0) : '100',
    );
    _servingSizeController = TextEditingController(
      text: p != null ? p.servingSize.toStringAsFixed(0) : '30',
    );
    _sugarController = TextEditingController(
      text: p?.sugarPer100 != null ? p!.sugarPer100!.toStringAsFixed(1) : '',
    );
    _addedSugarController = TextEditingController(
      text: p?.addedSugarPer100 != null ? p!.addedSugarPer100!.toStringAsFixed(1) : '',
    );
    _selectedCategory = (p?.category != null && _categories.contains(p!.category.toLowerCase()))
        ? p.category.toLowerCase()
        : 'biscuits';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _packSizeController.dispose();
    _servingSizeController.dispose();
    _sugarController.dispose();
    _addedSugarController.dispose();
    super.dispose();
  }

  Future<void> _runOcr(ImageSource source) async {
    setState(() {
      _isOcrProcessing = true;
      _ocrStatusMessage = null;
    });

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        setState(() => _isOcrProcessing = false);
        return;
      }

      final result = await NutritionLabelOcrParser.recognizeAndParse(pickedFile.path);

      if (!mounted) return;

      setState(() {
        _isOcrProcessing = false;
        if (result.sugarPer100 != null) {
          _sugarController.text = result.sugarPer100!.toStringAsFixed(1);
        }
        if (result.addedSugarPer100 != null) {
          _addedSugarController.text = result.addedSugarPer100!.toStringAsFixed(1);
        }
        if (result.servingSize != null) {
          _servingSizeController.text = result.servingSize!.toStringAsFixed(0);
        }

        if (result.hasSugar) {
          _ocrStatusMessage =
              '✓ Extracted: ${result.sugarPer100}g sugar${result.servingSize != null ? " • ${result.servingSize}g serving" : ""}';
        } else {
          _ocrStatusMessage =
              '⚠ Label scanned, but sugar value could not be confirmed. Please check the fields below.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isOcrProcessing = false;
        _ocrStatusMessage = 'Error scanning label: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final brand = _brandController.text.trim().isEmpty ? 'Generic' : _brandController.text.trim();
    final packSize = double.tryParse(_packSizeController.text.trim()) ?? 100.0;
    final servingSize = double.tryParse(_servingSizeController.text.trim()) ?? 30.0;

    final sugarText = _sugarController.text.trim();
    final double? sugarPer100 = sugarText.isNotEmpty ? double.tryParse(sugarText) : null;

    final addedSugarText = _addedSugarController.text.trim();
    final double? addedSugarPer100 = addedSugarText.isNotEmpty ? double.tryParse(addedSugarText) : null;

    final isLiquid = _selectedCategory == 'beverage';
    final basis = isLiquid ? 'per_100ml' : 'per_100g';

    // Generate household portions
    final portions = PortionBuilder.buildPortions(
      category: _selectedCategory,
      packSize: packSize,
      servingSize: servingSize,
      basis: isLiquid ? 'ml' : 'g',
    );

    final updatedProduct = Product(
      barcode: widget.barcode.trim(),
      name: name,
      brand: brand,
      category: _selectedCategory,
      packSize: packSize,
      servingSize: servingSize,
      sugarPer100: sugarPer100,
      addedSugarPer100: addedSugarPer100,
      sugarBasis: basis,
      portions: portions,
      hiddenSugarFlag: false,
      source: 'user-contributed',
      verified: false,
    );

    // Save in repository and database
    await ref.read(productRepositoryProvider).saveUserProduct(updatedProduct);

    if (mounted) {
      Navigator.of(context).pop();
      widget.onProductSaved(updatedProduct);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved product "${updatedProduct.name}"!'),
          backgroundColor: GlucioTheme.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: GlucioTheme.cardCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: GlucioTheme.inkBlack, width: 3),
          left: BorderSide(color: GlucioTheme.inkBlack, width: 3),
          right: BorderSide(color: GlucioTheme.inkBlack, width: 3),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Handle
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: GlucioTheme.inkBlack.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sheet Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add / Correct Food',
                          style: TextStyle(
                            fontFamily: GlucioTheme.fontDisplay,
                            fontSize: 22,
                            color: GlucioTheme.inkBlack,
                          ),
                        ),
                        Text(
                          'Save accurate nutrition info to your local catalog',
                          style: TextStyle(
                            fontFamily: GlucioTheme.fontBody,
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: GlucioTheme.pillDecoration(fill: GlucioTheme.bgCream),
                      child: Text(
                        widget.barcode,
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
                const SizedBox(height: 16),

                // OCR Action Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FBF7),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.document_scanner_rounded, size: 20, color: GlucioTheme.inkBlack),
                          SizedBox(width: 8),
                          Text(
                            'Smart OCR Label Scanner',
                            style: TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Photograph the nutrition panel on the pack to auto-fill sugar & servings.',
                        style: TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_isOcrProcessing)
                        const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: GlucioTheme.inkBlack),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Analyzing nutrition panel with ML Kit...',
                              style: TextStyle(
                                fontFamily: GlucioTheme.fontBody,
                                fontSize: 11,
                                color: GlucioTheme.inkBlack,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _runOcr(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt, size: 16),
                                label: const Text('Take Photo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GlucioTheme.accentLime,
                                  foregroundColor: GlucioTheme.inkBlack,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(color: GlucioTheme.inkBlack, width: 1.5),
                                  ),
                                  textStyle: const TextStyle(
                                    fontFamily: GlucioTheme.fontBody,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _runOcr(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library, size: 16),
                              label: const Text('Gallery'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: GlucioTheme.inkBlack,
                                side: const BorderSide(color: GlucioTheme.inkBlack, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: GlucioTheme.fontBody,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (_ocrStatusMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _ocrStatusMessage!,
                          style: TextStyle(
                            fontFamily: GlucioTheme.fontBody,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _ocrStatusMessage!.startsWith('✓')
                                ? GlucioTheme.primaryGreen
                                : Colors.deepOrange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Form Fields
                _buildField(
                  controller: _nameController,
                  label: 'Product Name',
                  hint: 'e.g. Parle-G Gold Biscuits',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
                ),
                const SizedBox(height: 12),

                _buildField(
                  controller: _brandController,
                  label: 'Brand / Manufacturer',
                  hint: 'e.g. Parle, Britannia, Nestle',
                ),
                const SizedBox(height: 12),

                // Category Dropdown
                const Text(
                  'Category',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: GlucioTheme.bgCream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      dropdownColor: GlucioTheme.bgCream,
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            c.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontSize: 12,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sugar Fields Row
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _sugarController,
                        label: 'Total Sugar (g/100g)',
                        hint: 'e.g. 25.5',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        controller: _addedSugarController,
                        label: 'Added Sugar (g)',
                        hint: 'Optional',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Pack & Serving Sizes
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _packSizeController,
                        label: 'Pack Size (g/ml)',
                        hint: '100',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        controller: _servingSizeController,
                        label: 'Serving Size (g/ml)',
                        hint: '25',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Save Action Button
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlucioTheme.inkBlack,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'SAVE PRODUCT & UPDATE',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: GlucioTheme.fontBody,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: GlucioTheme.inkBlack,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontFamily: GlucioTheme.fontBody,
            fontSize: 12,
            color: GlucioTheme.inkBlack,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 11),
            filled: true,
            fillColor: GlucioTheme.bgCream,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: GlucioTheme.inkBlack, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: GlucioTheme.primaryGreen, width: 2.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2.5),
            ),
          ),
        ),
      ],
    );
  }
}
