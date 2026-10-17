import 'package:flutter_test/flutter_test.dart';

/// Pure checksum validator for EAN-13 and EAN-8 barcodes.
bool isValidEanChecksum(String barcode) {
  final digits = barcode.trim();
  if (digits.length != 8 && digits.length != 13) return false;
  if (!RegExp(r'^\d+$').hasMatch(digits)) return false;

  final checkDigit = int.parse(digits[digits.length - 1]);
  final dataDigits = digits.substring(0, digits.length - 1);

  int sum = 0;
  if (digits.length == 13) {
    // EAN-13: alternating weights 1 and 3 on positions 0-11
    for (int i = 0; i < 12; i++) {
      final val = int.parse(dataDigits[i]);
      sum += (i % 2 == 0) ? val * 1 : val * 3;
    }
  } else {
    // EAN-8: alternating weights 3 and 1 on positions 0-6
    for (int i = 0; i < 7; i++) {
      final val = int.parse(dataDigits[i]);
      sum += (i % 2 == 0) ? val * 3 : val * 1;
    }
  }

  final computedCheck = (10 - (sum % 10)) % 10;
  return computedCheck == checkDigit;
}

void main() {
  group('EAN Checksum Validation Tests', () {
    test('validates valid Indian EAN-13 barcodes (890 prefix)', () {
      expect(isValidEanChecksum('8901063012134'), isTrue); // Parle-G
      expect(isValidEanChecksum('8901030383458'), isTrue); // Kissan Ketchup
      expect(isValidEanChecksum('8901764012211'), isTrue); // Thums Up
      expect(isValidEanChecksum('8901725181222'), isTrue); // Haldiram Alu Bhujia
    });

    test('validates valid EAN-8 barcodes', () {
      expect(isValidEanChecksum('89080443'), isTrue); // Maggi Tomato Sauce EAN-8
    });

    test('rejects corrupted check digits', () {
      expect(isValidEanChecksum('8901063012139'), isFalse);
      expect(isValidEanChecksum('89080449'), isFalse);
    });

    test('rejects invalid lengths or non-numeric characters', () {
      expect(isValidEanChecksum('12345'), isFalse);
      expect(isValidEanChecksum('890106301213A'), isFalse);
      expect(isValidEanChecksum(''), isFalse);
    });
  });
}
