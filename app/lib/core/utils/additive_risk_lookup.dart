/// Risk level classification for food additives.
enum AdditiveRiskLevel {
  low,
  moderate,
  high,
  unknown,
}

/// Information record for a parsed food additive (E-number).
class AdditiveInfo {
  final String code; // e.g. "E322"
  final String name; // e.g. "Lecithins"
  final String function; // e.g. "Emulsifier"
  final AdditiveRiskLevel riskLevel;
  final String? note;

  const AdditiveInfo({
    required this.code,
    required this.name,
    required this.function,
    required this.riskLevel,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'function': function,
        'risk_level': riskLevel.name,
        if (note != null) 'note': note,
      };

  factory AdditiveInfo.fromJson(Map<String, dynamic> json) => AdditiveInfo(
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? 'Unknown Additive',
        function: json['function'] as String? ?? 'Food Additive',
        riskLevel: AdditiveRiskLevel.values.firstWhere(
          (e) => e.name == json['risk_level'],
          orElse: () => AdditiveRiskLevel.unknown,
        ),
        note: json['note'] as String?,
      );
}

/// Offline lookup dictionary for common food additives and their risk levels.
class AdditiveRiskLookup {
  AdditiveRiskLookup._();

  static const Map<String, AdditiveInfo> _database = {
    'e100': AdditiveInfo(
      code: 'E100',
      name: 'Curcumin',
      function: 'Natural Color',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Extracted from turmeric roots.',
    ),
    'e102': AdditiveInfo(
      code: 'E102',
      name: 'Tartrazine',
      function: 'Synthetic Color',
      riskLevel: AdditiveRiskLevel.high,
      note: 'Azo dye; may trigger hyperactivity in children.',
    ),
    'e110': AdditiveInfo(
      code: 'E110',
      name: 'Sunset Yellow FCF',
      function: 'Synthetic Color',
      riskLevel: AdditiveRiskLevel.high,
      note: 'Azo dye; restricted in some European countries.',
    ),
    'e122': AdditiveInfo(
      code: 'E122',
      name: 'Azorubine (Carmoisine)',
      function: 'Synthetic Color',
      riskLevel: AdditiveRiskLevel.high,
      note: 'Azo dye; potential allergen.',
    ),
    'e129': AdditiveInfo(
      code: 'E129',
      name: 'Allura Red AC',
      function: 'Synthetic Color',
      riskLevel: AdditiveRiskLevel.high,
      note: 'Synthetic red dye; may affect activity/attention in children.',
    ),
    'e133': AdditiveInfo(
      code: 'E133',
      name: 'Brilliant Blue FCF',
      function: 'Synthetic Color',
      riskLevel: AdditiveRiskLevel.moderate,
      note: 'Synthetic triarylmethane dye.',
    ),
    'e150a': AdditiveInfo(
      code: 'E150a',
      name: 'Plain Caramel',
      function: 'Color',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Heated carbohydrates.',
    ),
    'e150d': AdditiveInfo(
      code: 'E150d',
      name: 'Sulphite Ammonia Caramel',
      function: 'Color',
      riskLevel: AdditiveRiskLevel.moderate,
      note: 'Common in colas; contains 4-MEI by-product.',
    ),
    'e160a': AdditiveInfo(
      code: 'E160a',
      name: 'Carotenes',
      function: 'Natural Color',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Plant-derived provitamin A.',
    ),
    'e171': AdditiveInfo(
      code: 'E171',
      name: 'Titanium Dioxide',
      function: 'White Pigment',
      riskLevel: AdditiveRiskLevel.high,
      note: 'Banned in the EU due to genotoxicity concerns.',
    ),
    'e200': AdditiveInfo(
      code: 'E200',
      name: 'Sorbic Acid',
      function: 'Preservative',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Inhibits yeasts and moulds.',
    ),
    'e202': AdditiveInfo(
      code: 'E202',
      name: 'Potassium Sorbate',
      function: 'Preservative',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Common in sauces, baked goods and fruit products.',
    ),
    'e211': AdditiveInfo(
      code: 'E211',
      name: 'Sodium Benzoate',
      function: 'Preservative',
      riskLevel: AdditiveRiskLevel.moderate,
      note: 'Widely used in acidic drinks and condiments.',
    ),
    'e220': AdditiveInfo(
      code: 'E220',
      name: 'Sulphur Dioxide',
      function: 'Preservative / Antioxidant',
      riskLevel: AdditiveRiskLevel.moderate,
      note: 'Can trigger asthmatic reactions in sensitive individuals.',
    ),
    'e250': AdditiveInfo(
      code: 'E250',
      name: 'Sodium Nitrite',
      function: 'Preservative / Curing Agent',
      riskLevel: AdditiveRiskLevel.high,
      note: 'Forms nitrosamines when cooked at high heat.',
    ),
    'e300': AdditiveInfo(
      code: 'E300',
      name: 'Ascorbic Acid (Vitamin C)',
      function: 'Antioxidant',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Natural vitamin C antioxidant.',
    ),
    'e322': AdditiveInfo(
      code: 'E322',
      name: 'Lecithins',
      function: 'Emulsifier',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Natural fatty substances derived from soy, sunflower, or egg.',
    ),
    'e330': AdditiveInfo(
      code: 'E330',
      name: 'Citric Acid',
      function: 'Acidity Regulator / Antioxidant',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Naturally occurring fruit acid.',
    ),
    'e407': AdditiveInfo(
      code: 'E407',
      name: 'Carrageenan',
      function: 'Thickener / Gelling Agent',
      riskLevel: AdditiveRiskLevel.moderate,
      note: 'Seaweed extract; investigated for gut inflammation.',
    ),
    'e412': AdditiveInfo(
      code: 'E412',
      name: 'Guar Gum',
      function: 'Thickener / Stabiliser',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Natural dietary fiber from guar beans.',
    ),
    'e415': AdditiveInfo(
      code: 'E415',
      name: 'Xanthan Gum',
      function: 'Thickener / Stabiliser',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Bacterial fermentation gum.',
    ),
    'e422': AdditiveInfo(
      code: 'E422',
      name: 'Glycerol',
      function: 'Humectant',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Sweet, non-toxic trihydroxy alcohol.',
    ),
    'e450': AdditiveInfo(
      code: 'E450',
      name: 'Diphosphates',
      function: 'Emulsifier / Raising Agent',
      riskLevel: AdditiveRiskLevel.moderate,
      note: 'Excess phosphorus intake may stress kidney function.',
    ),
    'e471': AdditiveInfo(
      code: 'E471',
      name: 'Mono- and Diglycerides of Fatty Acids',
      function: 'Emulsifier',
      riskLevel: AdditiveRiskLevel.moderate,
      note: 'Industrial fats; often marker of ultra-processing (NOVA 4).',
    ),
    'e476': AdditiveInfo(
      code: 'E476',
      name: 'Polyglycerol Polyricinoleate (PGPR)',
      function: 'Emulsifier',
      riskLevel: AdditiveRiskLevel.moderate,
      note: 'Used in chocolates to reduce cocoa butter cost.',
    ),
    'e500': AdditiveInfo(
      code: 'E500',
      name: 'Sodium Carbonates',
      function: 'Raising Agent / Acidity Regulator',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Baking soda / washing soda.',
    ),
    'e503': AdditiveInfo(
      code: 'E503',
      name: 'Ammonium Carbonates',
      function: 'Raising Agent',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Traditional baker\'s ammonia, dissipates during baking.',
    ),
    'e621': AdditiveInfo(
      code: 'E621',
      name: 'Monosodium Glutamate (MSG)',
      function: 'Flavour Enhancer',
      riskLevel: AdditiveRiskLevel.moderate,
      note: 'Umami enhancer; may trigger mild sensitivity in some individuals.',
    ),
    'e950': AdditiveInfo(
      code: 'E950',
      name: 'Acesulfame K',
      function: 'Artificial Sweetener',
      riskLevel: AdditiveRiskLevel.moderate,
      note: 'Calorie-free artificial sweetener.',
    ),
    'e951': AdditiveInfo(
      code: 'E951',
      name: 'Aspartame',
      function: 'Artificial Sweetener',
      riskLevel: AdditiveRiskLevel.moderate,
      note: 'Contains phenylalanine; labeled for PKU patients.',
    ),
    'e955': AdditiveInfo(
      code: 'E955',
      name: 'Sucralose',
      function: 'Artificial Sweetener',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Chlorinated sucrose derivative.',
    ),
    'e960': AdditiveInfo(
      code: 'E960',
      name: 'Steviol Glycosides (Stevia)',
      function: 'Natural Sweetener',
      riskLevel: AdditiveRiskLevel.low,
      note: 'Plant-derived sweetener from Stevia rebaudiana.',
    ),
  };

  /// Normalizes an additive tag or code (e.g. "en:e322", "E-322", "INS 322", "322") into "e322".
  static String normalizeTag(String tag) {
    var cleaned = tag.toLowerCase().trim();
    if (cleaned.startsWith('en:')) {
      cleaned = cleaned.substring(3);
    }
    cleaned = cleaned.replaceAll('-', '').replaceAll(' ', '');
    if (cleaned.startsWith('ins')) {
      cleaned = 'e${cleaned.substring(3)}';
    } else if (!cleaned.startsWith('e') && RegExp(r'^\d+').hasMatch(cleaned)) {
      cleaned = 'e$cleaned';
    }
    return cleaned;
  }

  /// Looks up risk and details for an additive tag.
  static AdditiveInfo lookup(String tag) {
    final key = normalizeTag(tag);
    if (_database.containsKey(key)) {
      return _database[key]!;
    }

    final codeFormatted = key.toUpperCase();
    return AdditiveInfo(
      code: codeFormatted,
      name: codeFormatted,
      function: 'Additive ($codeFormatted)',
      riskLevel: AdditiveRiskLevel.unknown,
      note: null,
    );
  }
}
