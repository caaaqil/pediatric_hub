/// Client-side validation that mirrors the backend Zod schemas exactly, so a
/// form never round-trips just to be told it is invalid.
class Validators {
  const Validators._();

  /// `z.string().email()`
  static String? email(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    final RegExp pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(text)) return 'Invalid email format';
    return null;
  }

  /// `strongPasswordSchema` in `backend/src/validators/auth.validator.js`:
  /// ≥8 chars, ≥1 letter, ≥1 number, ≥1 special character.
  static String? strongPassword(String? value) {
    final String text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[a-zA-Z]').hasMatch(text)) {
      return 'Password must contain at least one letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(text)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(text)) {
      return 'Password must contain at least one special character (!@#\$%^&*)';
    }
    return null;
  }

  /// Login only checks that a password was typed (`z.string().min(1)`).
  static String? password(String? value) {
    if ((value ?? '').isEmpty) return 'Password is required';
    return null;
  }

  static String? required(String? value, String label) {
    if ((value ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  static String? minLength(String? value, int min, String label) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    if (text.length < min) return '$label must be at least $min characters';
    return null;
  }

  static String? maxLength(String? value, int max, String label) {
    final String text = value?.trim() ?? '';
    if (text.length > max) return '$label must be at most $max characters';
    return null;
  }

  /// `POST /chatbot/templates` — `triggerKeyword` min 2, `response` min 5.
  static String? triggerKeyword(String? value) =>
      minLength(value, 2, 'Trigger keyword');

  static String? templateResponse(String? value) =>
      minLength(value, 5, 'Response');

  /// `ParentInfo.fullName` — min 2, max 120.
  static String? guardianName(String? value) {
    final String? tooShort = minLength(value, 2, 'Full name');
    if (tooShort != null) return tooShort;
    return maxLength(value, 120, 'Full name');
  }

  /// `ParentInfo.phoneNumber` — min 5, max 30.
  static String? guardianPhone(String? value) {
    final String? tooShort = minLength(value, 5, 'Phone number');
    if (tooShort != null) return tooShort;
    return maxLength(value, 30, 'Phone number');
  }

  /// `ParentInfo.address` — min 2, max 255.
  static String? guardianAddress(String? value) {
    final String? tooShort = minLength(value, 2, 'Address');
    if (tooShort != null) return tooShort;
    return maxLength(value, 255, 'Address');
  }

  /// `HealthService.name` — min 1, max 150.
  static String? serviceName(String? value) {
    final String? empty = required(value, 'Service name');
    if (empty != null) return empty;
    return maxLength(value, 150, 'Service name');
  }

  /// `z.number().nonnegative()` for service price, blank allowed.
  static String? optionalPrice(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final double? parsed = double.tryParse(text);
    if (parsed == null) return 'Enter a valid amount';
    if (parsed < 0) return 'Price cannot be negative';
    return null;
  }

  /// `z.number().positive()` for growth metrics, blank allowed.
  static String? optionalPositive(String? value, String label) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final double? parsed = double.tryParse(text);
    if (parsed == null) return 'Enter a valid $label';
    if (parsed <= 0) return '$label must be greater than zero';
    return null;
  }

  /// `z.number().int().min(1)` for vaccine dose numbers.
  static String? doseNumber(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Dose number is required';
    final int? parsed = int.tryParse(text);
    if (parsed == null) return 'Enter a whole number';
    if (parsed < 1) return 'Dose number starts at 1';
    return null;
  }

  /// The 6-digit OTP `POST /auth/forgot-password` emails out.
  static String? otp(String? value) {
    final String text = value?.trim() ?? '';
    if (text.length != 6 || int.tryParse(text) == null) {
      return 'Enter the 6-digit code';
    }
    return null;
  }

  /// EVC Plus wallet number, same rule the web booking flow enforces.
  static String? evcPhone(String? value) {
    final String text = (value ?? '').replaceAll(RegExp(r'\s+'), '');
    if (text.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^(252|0)\d{8,9}$').hasMatch(text)) {
      return 'Enter a valid Somali number (e.g. 2526XXXXXXX or 06XXXXXXX)';
    }
    return null;
  }

  static String? amount(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Amount is required';
    final double? parsed = double.tryParse(text);
    if (parsed == null) return 'Enter a valid amount';
    if (parsed <= 0) return 'Amount must be greater than zero';
    return null;
  }
}
