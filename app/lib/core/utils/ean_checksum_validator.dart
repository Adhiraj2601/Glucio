/// Pure checksum validator for EAN-13 and EAN-8 barcodes.
class EanChecksumValidator {
  EanChecksumValidator._();

  /// Validates EAN-13 or EAN-8 check digits using the standard modulo-10 algorithm.
  static bool isValid(String barcode) {
    final digits = barcode.trim();
    if (digits.length != 8 && digits.length != 13) return false;
    if (!RegExp(r'^\d+$').hasMatch(digits)) return false;

    final checkDigit = int.parse(digits[digits.length - 1]);
    final dataDigits = digits.substring(0, digits.length - 1);

    int sum = 0;
    if (digits.length == 13) {
      for (int i = 0; i < 12; i++) {
        final val = int.parse(dataDigits[i]);
        sum += (i % 2 == 0) ? val * 1 : val * 3;
      }
    } else {
      for (int i = 0; i < 7; i++) {
        final val = int.parse(dataDigits[i]);
        sum += (i % 2 == 0) ? val * 3 : val * 1;
      }
    }

    final computedCheck = (10 - (sum % 10)) % 10;
    return computedCheck == checkDigit;
  }
}
