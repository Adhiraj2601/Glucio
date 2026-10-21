import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Parsed nutrition facts extracted from a packaged food label photo.
class OcrNutritionResult {
  final double? sugarPer100;
  final double? addedSugarPer100;
  final double? carbohydratesPer100;
  final double? energyKcal;
  final double? servingSize;
  final int? servingsPerPack;
  final String sugarBasis; // 'per_100g' or 'per_serve'
  final String rawText;
  final List<String> matchedLines;

  const OcrNutritionResult({
    this.sugarPer100,
    this.addedSugarPer100,
    this.carbohydratesPer100,
    this.energyKcal,
    this.servingSize,
    this.servingsPerPack,
    this.sugarBasis = 'per_100g',
    required this.rawText,
    this.matchedLines = const [],
  });

  bool get hasSugar => sugarPer100 != null;
  bool get isEmpty =>
      sugarPer100 == null &&
      addedSugarPer100 == null &&
      carbohydratesPer100 == null &&
      energyKcal == null &&
      servingSize == null;

  @override
  String toString() {
    return 'OcrNutritionResult(sugar: $sugarPer100, addedSugar: $addedSugarPer100, carbs: $carbohydratesPer100, energy: $energyKcal, serving: $servingSize)';
  }
}

/// Heuristic parser for extracting nutrition panel values from raw OCR text.
///
/// Designed specifically for standard Indian packaged food labels (FSSAI mandatory formats).
class NutritionLabelOcrParser {
  NutritionLabelOcrParser._();

  /// Processes an image file using Google ML Kit on-device text recognition.
  static Future<OcrNutritionResult> recognizeAndParse(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await textRecognizer.processImage(inputImage);
      return parseText(recognizedText.text);
    } catch (e, stack) {
      debugPrint('Error performing ML Kit OCR: $e\n$stack');
      return OcrNutritionResult(rawText: 'OCR Error: $e');
    } finally {
      await textRecognizer.close();
    }
  }

  /// Extracts text from an ingredients photo using Google ML Kit on-device OCR.
  static Future<String> recognizeIngredients(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text.trim();
    } catch (e, stack) {
      debugPrint('Error recognizing ingredients OCR: $e\n$stack');
      return '';
    } finally {
      await textRecognizer.close();
    }
  }

  /// Parses raw recognized text string using regex patterns tailored for Indian nutrition labels.
  static OcrNutritionResult parseText(String rawText) {
    if (rawText.trim().isEmpty) {
      return const OcrNutritionResult(rawText: '');
    }

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final matchedLines = <String>[];
    double? sugar;
    double? addedSugar;
    double? carbs;
    double? energy;
    double? servingSize;
    int? servingsPerPack;

    // Detect if column indicates per 100g or per serve
    final isPer100g = _containsWord(rawText, ['per 100g', 'per 100 g', 'per 100ml', 'per 100 ml', '100g', '100 g']);
    final isPerServe = _containsWord(rawText, ['per serve', 'per serving', 'serving size', 'approx. per serve']);
    final sugarBasis = (isPerServe && !isPer100g) ? 'per_serve' : 'per_100g';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      // 1. Serving Size
      if (servingSize == null && _matchesServing(lineLower)) {
        final val = _extractFirstNumber(line);
        if (val != null && val > 0 && val <= 1000) {
          servingSize = val;
          matchedLines.add('Serving Size: $line');
        }
      }

      // 2. Servings per pack
      if (servingsPerPack == null && _matchesServingsPerPack(lineLower)) {
        final val = _extractFirstNumber(line);
        if (val != null && val >= 1 && val <= 500) {
          servingsPerPack = val.round();
          matchedLines.add('Servings/Pack: $line');
        }
      }

      // 3. Added Sugar (Check before total sugar so "added sugar" isn't matched as total sugar)
      if (addedSugar == null && _matchesAddedSugar(lineLower)) {
        final val = _extractNutritionValue(line, lines, i);
        if (val != null && val >= 0 && val <= 100) {
          addedSugar = val;
          matchedLines.add('Added Sugar: $line');
        }
      }

      // 4. Total Sugar
      if (sugar == null && _matchesTotalSugar(lineLower)) {
        final val = _extractNutritionValue(line, lines, i);
        if (val != null && val >= 0 && val <= 100) {
          sugar = val;
          matchedLines.add('Total Sugar: $line');
        }
      }

      // 5. Total Carbohydrates
      if (carbs == null && _matchesCarbohydrates(lineLower)) {
        final val = _extractNutritionValue(line, lines, i);
        if (val != null && val >= 0 && val <= 100) {
          carbs = val;
          matchedLines.add('Carbohydrates: $line');
        }
      }

      // 6. Energy / Calories
      if (energy == null && _matchesEnergy(lineLower)) {
        final val = _extractNutritionValue(line, lines, i);
        if (val != null && val >= 0 && val <= 2000) {
          energy = val;
          matchedLines.add('Energy: $line');
        }
      }
    }

    return OcrNutritionResult(
      sugarPer100: sugar,
      addedSugarPer100: addedSugar,
      carbohydratesPer100: carbs,
      energyKcal: energy,
      servingSize: servingSize,
      servingsPerPack: servingsPerPack,
      sugarBasis: sugarBasis,
      rawText: rawText,
      matchedLines: matchedLines,
    );
  }

  // Regex and matching helpers
  static bool _matchesAddedSugar(String text) {
    return text.contains('added sugar') ||
        text.contains('added sugars') ||
        text.contains('incl. added') ||
        text.contains('includes added');
  }

  static bool _matchesTotalSugar(String text) {
    if (_matchesAddedSugar(text)) return false;
    return text.contains('total sugar') ||
        text.contains('total sugars') ||
        text.contains('of which sugar') ||
        text.contains('of which sugars') ||
        text.contains('sugars') ||
        text.contains('sugar');
  }

  static bool _matchesCarbohydrates(String text) {
    if (_matchesTotalSugar(text) || _matchesAddedSugar(text)) return false;
    return text.contains('carbohydrate') ||
        text.contains('carbohydrates') ||
        text.contains('total carbohydrate') ||
        text.contains('total carbs') ||
        text.contains('carbs');
  }

  static bool _matchesEnergy(String text) {
    return text.contains('energy') ||
        text.contains('calories') ||
        text.contains('calorie') ||
        text.contains('kcal');
  }

  static bool _matchesServing(String text) {
    return text.contains('serving size') ||
        text.contains('per serve') ||
        text.contains('serve size') ||
        text.contains('one serving');
  }

  static bool _matchesServingsPerPack(String text) {
    return text.contains('servings per pack') ||
        text.contains('servings per package') ||
        text.contains('no. of servings');
  }

  static bool _containsWord(String text, List<String> targets) {
    final lower = text.toLowerCase();
    for (final t in targets) {
      if (lower.contains(t)) return true;
    }
    return false;
  }

  /// Extracts the nutrition number from the line itself or the next line if tabular.
  static double? _extractNutritionValue(String line, List<String> lines, int index) {
    // 1. Try extracting number on the same line
    final sameLineVal = _extractFirstNumber(line);
    if (sameLineVal != null) return sameLineVal;

    // 2. Tabular OCR: Next line might contain the numeric column
    if (index + 1 < lines.length) {
      final nextLine = lines[index + 1];
      final nextLineVal = _extractFirstNumber(nextLine);
      if (nextLineVal != null) return nextLineVal;
    }

    return null;
  }

  /// Finds and parses the first float or integer in a string, handling commas (25,5 -> 25.5).
  static double? _extractFirstNumber(String text) {
    // Regex matching numbers like 25.5, 25,5, 100, 3.2, 0.5
    final reg = RegExp(r'([0-9]+(?:[.,][0-9]+)?)');
    final match = reg.firstMatch(text);
    if (match != null) {
      final numStr = match.group(1)!.replaceAll(',', '.');
      return double.tryParse(numStr);
    }
    return null;
  }
}
