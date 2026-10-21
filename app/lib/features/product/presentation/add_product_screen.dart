import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../core/utils/nutrition_label_ocr_parser.dart';
import '../../../../core/utils/portion_builder.dart';
import '../../../data/datasources/local_product_database.dart';
import '../../../data/models/portion.dart';
import '../../../data/models/product.dart';
import 'product_result_screen.dart';

/// Screen allowing the user to add a missing product or correct nutrition data.
class AddProductScreen extends ConsumerStatefulWidget {
  final String initialBarcode;
  final String? initialName;
  final String? initialBrand;
  final String? initialCategory;
  final double? initialPackSize;
  final double? initialServingSize;

  const AddProductScreen({
    super.key,
    required this.initialBarcode,
    this.initialName,
    this.initialBrand,
    this.initialCategory,
    this.initialPackSize,
    this.initialServingSize,
  });

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _packSizeCtrl;
  late final TextEditingController _servingSizeCtrl;
  late final TextEditingController _sugarCtrl;
  late final TextEditingController _addedSugarCtrl;

  String _sugarBasis = 'per_100g';
  final List<Portion> _portions = [];
  bool _isOcrScanning = false;
  String? _ocrStatus;

  Future<void> _runOcr(ImageSource source) async {
    setState(() {
      _isOcrScanning = true;
      _ocrStatus = null;
    });

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 90);
      if (picked == null) {
        setState(() => _isOcrScanning = false);
        return;
      }

      final result = await NutritionLabelOcrParser.recognizeAndParse(picked.path);
      if (!mounted) return;

      setState(() {
        _isOcrScanning = false;
        if (result.sugarPer100 != null) {
          _sugarCtrl.text = result.sugarPer100!.toStringAsFixed(1);
        }
        if (result.addedSugarPer100 != null) {
          _addedSugarCtrl.text = result.addedSugarPer100!.toStringAsFixed(1);
        }
        if (result.servingSize != null) {
          _servingSizeCtrl.text = result.servingSize!.toStringAsFixed(0);
          _populateCategoryDefaults(_categoryCtrl.text);
        }

        if (result.hasSugar) {
          _ocrStatus = '✓ Extracted: ${result.sugarPer100}g sugar per 100g';
        } else {
          _ocrStatus = '⚠ Label text read, but sugar was not found. Please type it in below.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isOcrScanning = false;
        _ocrStatus = 'Error reading photo: $e';
      });
    }
  }

  final List<String> _categoryOptions = [
    'sauces',
    'ketchup',
    'biscuits',
    'namkeen',
    'chips',
    'makhana',
    'instant noodles',
    'beverage',
    'health drink',
    'bread',
    'sweets',
    'yogurt',
    'confectionery',
    'cereals',
  ];

  @override
  void initState() {
    super.initState();
    _barcodeCtrl = TextEditingController(text: widget.initialBarcode);
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _brandCtrl = TextEditingController(text: widget.initialBrand ?? '');
    _categoryCtrl = TextEditingController(
      text: widget.initialCategory ?? _categoryOptions.first,
    );
    _packSizeCtrl = TextEditingController(
      text: widget.initialPackSize != null ? widget.initialPackSize!.toStringAsFixed(0) : '100',
    );
    _servingSizeCtrl = TextEditingController(
      text: widget.initialServingSize != null ? widget.initialServingSize!.toStringAsFixed(0) : '30',
    );
    _sugarCtrl = TextEditingController();
    _addedSugarCtrl = TextEditingController();

    _populateCategoryDefaults(_categoryCtrl.text);
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _categoryCtrl.dispose();
    _packSizeCtrl.dispose();
    _servingSizeCtrl.dispose();
    _sugarCtrl.dispose();
    _addedSugarCtrl.dispose();
    super.dispose();
  }

  void _populateCategoryDefaults(String cat) {
    setState(() {
      _portions.clear();
      final pack = double.tryParse(_packSizeCtrl.text) ?? 100.0;
      final serv = double.tryParse(_servingSizeCtrl.text) ?? 30.0;
      final built = PortionBuilder.buildPortions(
        category: cat,
        packSize: pack,
        servingSize: serv,
        basis: _sugarBasis == 'per_100ml' ? 'ml' : 'g',
      );
      _portions.addAll(built);
    });
  }

  void _addCustomPortionDialog() {
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlucioTheme.cardCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: GlucioTheme.inkBlack, width: 2),
        ),
        title: const Text(
          'Add Household Portion',
          style: TextStyle(fontFamily: GlucioTheme.fontDisplay),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Portion Name',
                hintText: 'e.g. 1 bowl, 2 biscuits, 1 scoop',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (${_sugarBasis == 'per_100ml' ? 'ml' : 'g'})',
                hintText: 'e.g. 30',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: GlucioTheme.inkBlack)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GlucioTheme.primaryGreen,
              side: const BorderSide(color: GlucioTheme.inkBlack, width: 2),
            ),
            onPressed: () {
              final label = labelCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text.trim());
              if (label.isNotEmpty && amount != null && amount > 0) {
                setState(() {
                  _portions.insert(
                    0,
                    Portion(
                      label: label,
                      amount: amount,
                      basis: _sugarBasis == 'per_100ml' ? 'ml' : 'g',
                      kind: 'serving',
                      source: 'label',
                    ),
                  );
                });
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add Portion'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final barcode = _barcodeCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final brand = _brandCtrl.text.trim();
    final category = _categoryCtrl.text.trim();
    final packSize = double.tryParse(_packSizeCtrl.text.trim()) ?? 100.0;
    final servingSize = double.tryParse(_servingSizeCtrl.text.trim()) ?? 30.0;
    final sugar = double.tryParse(_sugarCtrl.text.trim());
    final addedSugar = double.tryParse(_addedSugarCtrl.text.trim());

    if (sugar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter sugar per 100g/ml.')),
      );
      return;
    }

    final product = Product(
      barcode: barcode,
      name: name,
      brand: brand.isNotEmpty ? brand : 'Generic',
      category: category,
      packSize: packSize,
      servingSize: servingSize,
      sugarPer100: sugar,
      addedSugarPer100: addedSugar,
      sugarBasis: _sugarBasis,
      portions: _portions,
      hiddenSugarFlag: false,
      source: 'user',
      verified: false,
    );

    // Save locally into SQLite user database
    await LocalProductDatabase.instance.saveProduct(product);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product saved locally! Showing sugar breakdown...'),
      ),
    );

    // Replace current screen with product result screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProductResultScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlucioTheme.bgCream,
      appBar: AppBar(
        title: const Text('Add or Correct Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Smart OCR Label Scanner Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4FBF7),
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
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.document_scanner_rounded, size: 22, color: GlucioTheme.inkBlack),
                        SizedBox(width: 8),
                        Text(
                          'Scan Nutrition Label (OCR)',
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
                      'Take a photo of the nutrition facts table to auto-fill sugar, calories, and servings.',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isOcrScanning)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: GlucioTheme.inkBlack),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Reading label with Google ML Kit...',
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
                                  borderRadius: BorderRadius.circular(10),
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
                                borderRadius: BorderRadius.circular(10),
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
                    if (_ocrStatus != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _ocrStatus!,
                        style: TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _ocrStatus!.startsWith('✓')
                              ? GlucioTheme.primaryGreen
                              : Colors.deepOrange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: GlucioTheme.cardDecoration(
                  surface: const Color(0xFFE8F5E9),
                  radius: 16,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: GlucioTheme.inkBlack),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Saved products are stored locally on your device and will be recognized instantly on all future scans.',
                        style: TextStyle(
                          fontSize: 12,
                          color: GlucioTheme.inkBlack,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Barcode (Read-only or editable)
              _buildSectionTitle('Barcode Number'),
              TextFormField(
                controller: _barcodeCtrl,
                readOnly: true,
                decoration: _inputDecoration(prefixIcon: Icons.qr_code),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Product Name & Brand
              _buildSectionTitle('Product Name *'),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration(hintText: 'e.g. Maggi Tomato Sauce'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Product name is required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Brand'),
                        TextFormField(
                          controller: _brandCtrl,
                          decoration: _inputDecoration(hintText: 'e.g. Nestle'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Category'),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _categoryOptions.contains(_categoryCtrl.text)
                              ? _categoryCtrl.text
                              : _categoryOptions.first,
                          decoration: _inputDecoration(),
                          items: _categoryOptions.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              _categoryCtrl.text = val;
                              _populateCategoryDefaults(val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Basis toggle: per 100g vs per 100ml
              _buildSectionTitle('Nutrition Basis'),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'per_100g', label: Text('Per 100 g (Solids)')),
                  ButtonSegment(value: 'per_100ml', label: Text('Per 100 ml (Liquids)')),
                ],
                selected: {_sugarBasis},
                onSelectionChanged: (set) {
                  setState(() {
                    _sugarBasis = set.first;
                    _populateCategoryDefaults(_categoryCtrl.text);
                  });
                },
              ),
              const SizedBox(height: 20),

              // Sugar Per 100g / 100ml (Required) with explicit guidance hint
              _buildSectionTitle('Sugar per 100 ${_sugarBasis == 'per_100ml' ? "ml" : "g"} *'),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20, color: GlucioTheme.inkBlack),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Use the 'per 100 g' column on the label. If it only shows 'per serve', divide by the serve size and multiply by 100.",
                        style: TextStyle(
                          fontSize: 12,
                          color: GlucioTheme.inkBlack,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: _sugarCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  hintText: 'e.g. 33.0',
                  suffixText: _sugarBasis == 'per_100ml' ? 'g / 100ml' : 'g / 100g',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Sugar per 100g/ml is required';
                  final d = double.tryParse(v.trim());
                  if (d == null || d < 0) return 'Enter a valid number >= 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Added Sugar (Optional)
              _buildSectionTitle('Added Sugar per 100 ${_sugarBasis == 'per_100ml' ? "ml" : "g"} (Optional)'),
              TextFormField(
                controller: _addedSugarCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  hintText: 'Leave empty if not declared on pack',
                  suffixText: 'g',
                ),
              ),
              const SizedBox(height: 16),

              // Pack Size & Serving Size
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Pack Size (${_sugarBasis == 'per_100ml' ? "ml" : "g"})'),
                        TextFormField(
                          controller: _packSizeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(hintText: 'e.g. 200'),
                          onChanged: (_) => _populateCategoryDefaults(_categoryCtrl.text),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Serving Size (${_sugarBasis == 'per_100ml' ? "ml" : "g"})'),
                        TextFormField(
                          controller: _servingSizeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(hintText: 'e.g. 15'),
                          onChanged: (_) => _populateCategoryDefaults(_categoryCtrl.text),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Household Portions List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Household Portions'),
                  TextButton.icon(
                    onPressed: _addCustomPortionDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Portion'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _portions.map((p) {
                  return Chip(
                    backgroundColor: p.isEstimate ? GlucioTheme.cardCream : GlucioTheme.accentLime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: const BorderSide(color: GlucioTheme.inkBlack, width: 2),
                    ),
                    label: Text(
                      '${p.label} (${p.amount.toStringAsFixed(0)}${p.basis})${p.isEstimate ? " [about]" : ""}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlucioTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: GlucioTheme.inkBlack, width: 2),
                  ),
                  elevation: 0,
                ),
                onPressed: _saveProduct,
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Save & See Sugar Breakdown',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontDisplay,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: GlucioTheme.inkBlack,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText, String? suffixText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      suffixText: suffixText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: GlucioTheme.inkBlack) : null,
      filled: true,
      fillColor: GlucioTheme.cardCream,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GlucioTheme.inkBlack, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GlucioTheme.inkBlack, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GlucioTheme.inkBlack, width: 2.5),
      ),
    );
  }
}
