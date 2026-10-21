import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/glucio_theme.dart';
import '../../../core/utils/ean_checksum_validator.dart';
import '../../../core/utils/nutrition_label_ocr_parser.dart';
import '../../../core/utils/portion_builder.dart';
import '../../../data/datasources/local_product_database.dart';
import '../../../data/models/portion.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_details.dart';
import '../../../data/repositories/off_repository.dart';
import 'product_result_screen.dart';

/// Comprehensive Neo-Brutalist screen for adding missing products or editing
/// product details, ingredients, allergens, and photos with offline contribution sync.
class AddProductScreen extends ConsumerStatefulWidget {
  final String initialBarcode;
  final String? initialName;
  final String? initialBrand;
  final String? initialCategory;
  final double? initialPackSize;
  final double? initialServingSize;
  final double? initialSugar;

  const AddProductScreen({
    super.key,
    required this.initialBarcode,
    this.initialName,
    this.initialBrand,
    this.initialCategory,
    this.initialPackSize,
    this.initialServingSize,
    this.initialSugar,
  });

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _packSizeCtrl;
  late final TextEditingController _servingSizeCtrl;
  late final TextEditingController _sugarCtrl;
  late final TextEditingController _addedSugarCtrl;

  // OFF Parity: Extended Nutriments
  late final TextEditingController _energyKcalCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _satFatCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fiberCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _saltCtrl;

  // Ingredients & Analysis
  late final TextEditingController _ingredientsCtrl;

  String _sugarBasis = 'per_100g';
  final List<Portion> _portions = [];

  // Photo paths
  String? _frontPhotoPath;
  String? _ingredientsPhotoPath;
  String? _nutritionPhotoPath;

  // Allergens & Dietary
  final Set<String> _selectedAllergens = {};
  String _veganStatus = 'unknown'; // 'yes', 'no', 'unknown'
  String _vegetarianStatus = 'unknown'; // 'yes', 'no', 'unknown'
  String _palmOilStatus = 'unknown'; // 'yes', 'no', 'unknown'

  // Open Food Facts Community Contribution
  bool _contributeToOff = true;

  // OCR state
  bool _isOcrScanning = false;
  String? _ocrStatus;

  final List<String> _commonAllergens = [
    'milk',
    'gluten',
    'peanuts',
    'tree_nuts',
    'soybeans',
    'eggs',
    'fish',
    'sesame_seeds',
    'mustard',
    'crustaceans',
  ];

  final List<String> _categoryOptions = [
    'biscuits',
    'beverage',
    'instant noodles',
    'sauces',
    'namkeen',
    'chips',
    'dairy',
    'confectionery',
    'cereals',
    'bread',
    'sweets',
    'ketchup',
    'makhana',
    'health drink',
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
      text: widget.initialPackSize != null
          ? widget.initialPackSize!.toStringAsFixed(0)
          : '100',
    );
    _servingSizeCtrl = TextEditingController(
      text: widget.initialServingSize != null
          ? widget.initialServingSize!.toStringAsFixed(0)
          : '30',
    );
    _sugarCtrl = TextEditingController(
      text: widget.initialSugar != null
          ? widget.initialSugar!.toStringAsFixed(1)
          : '',
    );
    _addedSugarCtrl = TextEditingController();

    _energyKcalCtrl = TextEditingController();
    _fatCtrl = TextEditingController();
    _satFatCtrl = TextEditingController();
    _carbsCtrl = TextEditingController();
    _fiberCtrl = TextEditingController();
    _proteinCtrl = TextEditingController();
    _saltCtrl = TextEditingController();

    _ingredientsCtrl = TextEditingController();

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

    _energyKcalCtrl.dispose();
    _fatCtrl.dispose();
    _satFatCtrl.dispose();
    _carbsCtrl.dispose();
    _fiberCtrl.dispose();
    _proteinCtrl.dispose();
    _saltCtrl.dispose();
    _ingredientsCtrl.dispose();

    super.dispose();
  }

  void _populateCategoryDefaults(String cat) {
    _portions.clear();
    final pack = double.tryParse(_packSizeCtrl.text) ?? 100.0;
    final srv = double.tryParse(_servingSizeCtrl.text) ?? 30.0;
    final basisUnit = _sugarBasis == 'per_100ml' ? 'ml' : 'g';

    final defaults = PortionBuilder.buildPortions(
      category: cat,
      packSize: pack,
      servingSize: srv,
      basis: basisUnit,
    );

    setState(() {
      _portions.addAll(defaults);
    });
  }

  Future<void> _pickPhoto(String type, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      setState(() {
        if (type == 'front') {
          _frontPhotoPath = picked.path;
        } else if (type == 'ingredients') {
          _ingredientsPhotoPath = picked.path;
        } else if (type == 'nutrition') {
          _nutritionPhotoPath = picked.path;
        }
      });

      // If user snapped ingredients, offer auto-text extraction
      if (type == 'ingredients') {
        _runIngredientsOcr(picked.path);
      } else if (type == 'nutrition') {
        _runNutritionOcr(picked.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick photo: $e')),
      );
    }
  }

  Future<void> _runNutritionOcr(String imagePath) async {
    setState(() {
      _isOcrScanning = true;
      _ocrStatus = null;
    });

    try {
      final result = await NutritionLabelOcrParser.recognizeAndParse(imagePath);
      if (!mounted) return;

      setState(() {
        _isOcrScanning = false;
        if (result.sugarPer100 != null) {
          _sugarCtrl.text = result.sugarPer100!.toStringAsFixed(1);
        }
        if (result.addedSugarPer100 != null) {
          _addedSugarCtrl.text = result.addedSugarPer100!.toStringAsFixed(1);
        }
        if (result.carbohydratesPer100 != null) {
          _carbsCtrl.text = result.carbohydratesPer100!.toStringAsFixed(1);
        }
        if (result.energyKcal != null) {
          _energyKcalCtrl.text = result.energyKcal!.toStringAsFixed(0);
        }
        if (result.servingSize != null) {
          _servingSizeCtrl.text = result.servingSize!.toStringAsFixed(0);
          _populateCategoryDefaults(_categoryCtrl.text);
        }

        if (result.hasSugar) {
          _ocrStatus = '✓ Extracted: ${result.sugarPer100}g sugar per 100g';
        } else {
          _ocrStatus =
              '⚠ Label text read, but sugar was not found. Please type it in below.';
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

  Future<void> _runIngredientsOcr(String imagePath) async {
    try {
      final text = await NutritionLabelOcrParser.recognizeIngredients(imagePath);
      if (!mounted) return;
      if (text.isNotEmpty) {
        setState(() {
          _ingredientsCtrl.text = text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingredients extracted via ML Kit OCR!')),
        );
      }
    } catch (_) {}
  }

  void _addCustomPortionDialog() {
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlucioTheme.bgCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GlucioTheme.inkBlack, width: 2),
        ),
        title: const Text(
          'Add Custom Portion',
          style: TextStyle(
            fontFamily: GlucioTheme.fontDisplay,
            fontSize: 18,
            color: GlucioTheme.inkBlack,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: _inputDecoration(hintText: 'e.g. 1 slice, 2 cookies'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration(
                hintText: 'Amount',
                suffixText: _sugarBasis == 'per_100ml' ? 'ml' : 'g',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: GlucioTheme.inkBlack)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlucioTheme.accentLime,
              foregroundColor: GlucioTheme.inkBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: GlucioTheme.inkBlack, width: 1.5),
              ),
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

    // Extended Nutriments
    final nutriments = FullNutriments(
      energyKcal100g: double.tryParse(_energyKcalCtrl.text.trim()),
      fat100g: double.tryParse(_fatCtrl.text.trim()),
      saturatedFat100g: double.tryParse(_satFatCtrl.text.trim()),
      carbohydrates100g: double.tryParse(_carbsCtrl.text.trim()),
      sugars100g: sugar,
      fiber100g: double.tryParse(_fiberCtrl.text.trim()),
      proteins100g: double.tryParse(_proteinCtrl.text.trim()),
      salt100g: double.tryParse(_saltCtrl.text.trim()),
    );

    // Extended Product Details
    final details = ProductDetails(
      barcode: barcode,
      quantity:
          '${packSize.toStringAsFixed(0)} ${_sugarBasis == "per_100ml" ? "ml" : "g"}',
      ingredientsText: _ingredientsCtrl.text.trim().isNotEmpty
          ? _ingredientsCtrl.text.trim()
          : null,
      allergenTags: _selectedAllergens.toList(),
      traceTags: const [],
      additiveTags: const [],
      labelTags: const [],
      origins: null,
      packaging: null,
      nutriScoreGrade: null, // Computed when synced with OFF
      novaGroup: null,
      ecoScoreGrade: null,
      nutrientLevels: null,
      fullNutriments: nutriments,
      ingredientsAnalysis: IngredientsAnalysis(
        vegan: _veganStatus,
        vegetarian: _vegetarianStatus,
        palmOil: _palmOilStatus,
      ),
      imageUrls: ProductImageUrls(
        front: _frontPhotoPath,
        ingredients: _ingredientsPhotoPath,
        nutrition: _nutritionPhotoPath,
      ),
      rawOffJson: null,
      fetchedAt: DateTime.now(),
    );

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
      details: details,
    );

    // 1. Save product & details locally in SQLite
    await LocalProductDatabase.instance.saveProduct(product);
    await LocalProductDatabase.instance.saveProductDetails(details);

    // 2. Queue for Open Food Facts background sync if enabled
    if (_contributeToOff) {
      final contributionPayload = {
        'product_name': name,
        'brands': brand.isNotEmpty ? brand : 'Generic',
        'quantity':
            '${packSize.toStringAsFixed(0)} ${_sugarBasis == "per_100ml" ? "ml" : "g"}',
        'ingredients_text': _ingredientsCtrl.text.trim(),
        'sugars': sugar,
        'energy': double.tryParse(_energyKcalCtrl.text.trim()),
        'fat': double.tryParse(_fatCtrl.text.trim()),
        'proteins': double.tryParse(_proteinCtrl.text.trim()),
        'salt': double.tryParse(_saltCtrl.text.trim()),
        'allergens': _selectedAllergens.join(','),
      };

      await LocalProductDatabase.instance.queuePendingContribution(
        barcode,
        contributionPayload,
      );

      // Trigger sync worker asynchronously without blocking
      ref.read(pendingContributionsProvider.notifier).syncQueue();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_contributeToOff
            ? 'Product saved! Queued for Open Food Facts community sync.'
            : 'Product saved locally! Showing sugar breakdown...'),
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
    final isValidBarcode = EanChecksumValidator.isValid(_barcodeCtrl.text);

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
              // 1. BARCODE & STATUS CARD
              Container(
                padding: const EdgeInsets.all(14),
                decoration: GlucioTheme.cardDecoration(
                  surface: GlucioTheme.cardCream,
                  radius: 14,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2_rounded,
                        size: 32, color: GlucioTheme.inkBlack),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _barcodeCtrl.text,
                            style: const TextStyle(
                              fontFamily: GlucioTheme.fontDisplay,
                              fontSize: 16,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                isValidBarcode
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_rounded,
                                size: 14,
                                color: isValidBarcode
                                    ? GlucioTheme.primaryGreen
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isValidBarcode
                                    ? 'Valid EAN Checksum'
                                    : 'Non-standard barcode format',
                                style: TextStyle(
                                  fontFamily: GlucioTheme.fontBody,
                                  fontSize: 11,
                                  color: isValidBarcode
                                      ? GlucioTheme.primaryGreen
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: GlucioTheme.accentLime,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                      ),
                      child: const Text(
                        'OFF Contribution',
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
              ),
              const SizedBox(height: 16),

              // 2. PRODUCT PHOTOS CARD (Front, Ingredients, Nutrition)
              _buildSectionTitle('Product Photos (3 Angles)'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: GlucioTheme.cardDecoration(
                  surface: Colors.white,
                  radius: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Photos help the community verify nutrition information and ingredient changes.',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildPhotoSlot(
                          label: 'Front Pack',
                          icon: Icons.inventory_2_outlined,
                          path: _frontPhotoPath,
                          type: 'front',
                        ),
                        const SizedBox(width: 8),
                        _buildPhotoSlot(
                          label: 'Ingredients',
                          icon: Icons.list_alt_rounded,
                          path: _ingredientsPhotoPath,
                          type: 'ingredients',
                        ),
                        const SizedBox(width: 8),
                        _buildPhotoSlot(
                          label: 'Nutrition',
                          icon: Icons.table_chart_outlined,
                          path: _nutritionPhotoPath,
                          type: 'nutrition',
                        ),
                      ],
                    ),
                    if (_isOcrScanning) ...[
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: GlucioTheme.inkBlack),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Reading label with Google ML Kit...',
                            style: TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_ocrStatus != null) ...[
                      const SizedBox(height: 8),
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
              const SizedBox(height: 18),

              // 3. BASIC PRODUCT INFO
              _buildSectionTitle('Product Name *'),
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    _inputDecoration(hintText: 'e.g. Parle-G Gluco Biscuits'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Product name is required'
                    : null,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Brand'),
                        TextFormField(
                          controller: _brandCtrl,
                          decoration: _inputDecoration(hintText: 'e.g. Parle'),
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
                          initialValue:
                              _categoryOptions.contains(_categoryCtrl.text)
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
              const SizedBox(height: 14),

              // Nutrition Basis
              _buildSectionTitle('Nutrition Basis'),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'per_100g', label: Text('Per 100 g (Solids)')),
                  ButtonSegment(
                      value: 'per_100ml', label: Text('Per 100 ml (Liquids)')),
                ],
                selected: {_sugarBasis},
                onSelectionChanged: (set) {
                  setState(() {
                    _sugarBasis = set.first;
                    _populateCategoryDefaults(_categoryCtrl.text);
                  });
                },
              ),
              const SizedBox(height: 18),

              // 4. HERO SUGAR DATA (Glucio Hero)
              _buildSectionTitle(
                  'Sugar per 100 ${_sugarBasis == "per_100ml" ? "ml" : "g"} (Hero Metric) *'),
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
                    Icon(Icons.lightbulb_outline,
                        size: 20, color: GlucioTheme.inkBlack),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This is Glucio's core hero metric, translated directly into teaspoons and physical cubes against WHO's 25g limit.",
                        style: TextStyle(
                          fontSize: 11,
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  hintText: 'e.g. 25.5',
                  suffixText:
                      _sugarBasis == 'per_100ml' ? 'g / 100ml' : 'g / 100g',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Sugar per 100g/ml is required';
                  }
                  final d = double.tryParse(v.trim());
                  if (d == null || d < 0) return 'Enter a valid number >= 0';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Added Sugar
              _buildSectionTitle(
                  'Added Sugar per 100 ${_sugarBasis == "per_100ml" ? "ml" : "g"} (Optional)'),
              TextFormField(
                controller: _addedSugarCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  hintText: 'Leave blank if not declared on package',
                  suffixText: 'g',
                ),
              ),
              const SizedBox(height: 14),

              // Pack and Serving Size
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                            'Pack Size (${_sugarBasis == "per_100ml" ? "ml" : "g"})'),
                        TextFormField(
                          controller: _packSizeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(hintText: 'e.g. 250'),
                          onChanged: (_) =>
                              _populateCategoryDefaults(_categoryCtrl.text),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                            'Serving Size (${_sugarBasis == "per_100ml" ? "ml" : "g"})'),
                        TextFormField(
                          controller: _servingSizeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(hintText: 'e.g. 25'),
                          onChanged: (_) =>
                              _populateCategoryDefaults(_categoryCtrl.text),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Household Portions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Household Portions'),
                  TextButton.icon(
                    onPressed: _addCustomPortionDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Custom'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _portions.map((p) {
                  return Chip(
                    backgroundColor: p.isEstimate
                        ? GlucioTheme.cardCream
                        : GlucioTheme.accentLime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: const BorderSide(
                          color: GlucioTheme.inkBlack, width: 1.5),
                    ),
                    label: Text(
                      '${p.label} (${p.amount.toStringAsFixed(0)}${p.basis})',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 5. EXTENDED NUTRITION FACTS (OFF Parity)
              _buildSectionTitle('Extended Nutrition Facts (Per 100g/ml)'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: GlucioTheme.cardDecoration(
                  surface: Colors.white,
                  radius: 14,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _energyKcalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                                hintText: 'Calories', suffixText: 'kcal'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _carbsCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _inputDecoration(
                                hintText: 'Carbs', suffixText: 'g'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fatCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _inputDecoration(
                                hintText: 'Total Fat', suffixText: 'g'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _satFatCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _inputDecoration(
                                hintText: 'Sat. Fat', suffixText: 'g'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _proteinCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _inputDecoration(
                                hintText: 'Protein', suffixText: 'g'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _fiberCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _inputDecoration(
                                hintText: 'Fiber', suffixText: 'g'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _saltCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                          hintText: 'Salt / Sodium', suffixText: 'g'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. INGREDIENTS & ALLERGENS (OFF Parity)
              _buildSectionTitle('Ingredients Text'),
              TextFormField(
                controller: _ingredientsCtrl,
                maxLines: 4,
                decoration: _inputDecoration(
                  hintText:
                      'e.g. Wheat flour, sugar, edible vegetable oil, invert sugar syrup, milk solids, raising agents (503(ii), 500(ii)), salt, emulsifier (322).',
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Allergens Declared on Pack'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _commonAllergens.map((alg) {
                  final isSelected = _selectedAllergens.contains(alg);
                  final display = alg.replaceAll('_', ' ').toUpperCase();
                  return FilterChip(
                    label: Text(display),
                    selected: isSelected,
                    selectedColor: GlucioTheme.accentLime,
                    backgroundColor: GlucioTheme.cardCream,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: GlucioTheme.inkBlack,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    labelStyle: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: GlucioTheme.inkBlack,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAllergens.add(alg);
                        } else {
                          _selectedAllergens.remove(alg);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              _buildSectionTitle('Dietary Analysis'),
              _buildDietarySelector(
                title: 'Vegetarian',
                value: _vegetarianStatus,
                onChanged: (v) => setState(() => _vegetarianStatus = v),
              ),
              const SizedBox(height: 8),
              _buildDietarySelector(
                title: 'Vegan',
                value: _veganStatus,
                onChanged: (v) => setState(() => _veganStatus = v),
              ),
              const SizedBox(height: 8),
              _buildDietarySelector(
                title: 'Palm Oil Free',
                value: _palmOilStatus,
                onChanged: (v) => setState(() => _palmOilStatus = v),
              ),
              const SizedBox(height: 24),

              // 7. COMMUNITY CONTRIBUTION CHECKBOX
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _contributeToOff,
                      activeColor: GlucioTheme.primaryGreen,
                      onChanged: (val) {
                        setState(() {
                          _contributeToOff = val ?? true;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contribute to Open Food Facts',
                            style: TextStyle(
                              fontFamily: GlucioTheme.fontDisplay,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Help thousands of people make conscious dietary choices. Shared under the Open Database License (ODbL). Works completely offline with automatic sync.',
                            style: TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontSize: 11,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 8. SAVE BUTTON
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlucioTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side:
                        const BorderSide(color: GlucioTheme.inkBlack, width: 2),
                  ),
                  elevation: 0,
                ),
                onPressed: _saveProduct,
                icon: const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 22),
                label: const Text(
                  'Save & See Sugar Breakdown',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontDisplay,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSlot({
    required String label,
    required IconData icon,
    required String? path,
    required String type,
  }) {
    final hasPhoto = path != null;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: GlucioTheme.bgCream,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              side: BorderSide(color: GlucioTheme.inkBlack, width: 2),
            ),
            builder: (ctx) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt_rounded,
                        color: GlucioTheme.inkBlack),
                    title: const Text('Take Photo with Camera'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _pickPhoto(type, ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_rounded,
                        color: GlucioTheme.inkBlack),
                    title: const Text('Choose from Gallery'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _pickPhoto(type, ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: Container(
          height: 90,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hasPhoto
                ? GlucioTheme.accentLime.withValues(alpha: 0.3)
                : GlucioTheme.cardCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: GlucioTheme.inkBlack,
              width: hasPhoto ? 2 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasPhoto ? Icons.check_circle_rounded : icon,
                color: hasPhoto
                    ? GlucioTheme.primaryGreen
                    : GlucioTheme.inkBlack,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                hasPhoto ? 'Photo Added' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: hasPhoto
                      ? GlucioTheme.primaryGreen
                      : GlucioTheme.inkBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDietarySelector({
    required String title,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: GlucioTheme.fontBody,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: GlucioTheme.inkBlack,
          ),
        ),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'yes', label: Text('Yes')),
            ButtonSegment(value: 'no', label: Text('No')),
            ButtonSegment(value: 'unknown', label: Text('?')),
          ],
          selected: {value},
          onSelectionChanged: (set) => onChanged(set.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: GlucioTheme.inkBlack,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    String? suffixText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixText: suffixText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: GlucioTheme.inkBlack)
          : null,
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
