/// Shared password policy for `set-new-password` and `change-password`.
///
/// Backend rule (both endpoints): minimum 6 characters, at least one
/// uppercase letter, one lowercase letter, one number, one symbol, and the
/// password cannot be the literal string "123456". Keep this in sync with
/// the backend validator.
class PasswordRules {
  PasswordRules._();

  static const int minLength = 6;
  static const String disallowedPassword = '123456';

  static final RegExp _uppercase = RegExp(r'[A-Z]');
  static final RegExp _lowercase = RegExp(r'[a-z]');
  static final RegExp _number = RegExp(r'[0-9]');
  // Symbol = anything that isn't a letter or digit.
  static final RegExp _symbol = RegExp(r'[^A-Za-z0-9]');

  static bool hasMinLength(String password) => password.length >= minLength;
  static bool hasUppercase(String password) => _uppercase.hasMatch(password);
  static bool hasLowercase(String password) => _lowercase.hasMatch(password);
  static bool hasNumber(String password) => _number.hasMatch(password);
  static bool hasSymbol(String password) => _symbol.hasMatch(password);
  static bool isNotDisallowed(String password) =>
      password != disallowedPassword;

  static bool isValid(String password) =>
      hasMinLength(password) &&
      hasUppercase(password) &&
      hasLowercase(password) &&
      hasNumber(password) &&
      hasSymbol(password) &&
      isNotDisallowed(password);

  /// Returns the first violated rule's message, or null if [password] meets
  /// every rule. Check order matches the requirement list.
  static String? firstError(String password) {
    if (!hasMinLength(password)) {
      return 'Password must be at least $minLength characters';
    }
    if (!hasUppercase(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!hasLowercase(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!hasNumber(password)) {
      return 'Password must contain at least one number';
    }
    if (!hasSymbol(password)) {
      return 'Password must contain at least one symbol (e.g. ! @ # \$ %)';
    }
    if (!isNotDisallowed(password)) {
      return 'This password is too common. Please choose a stronger password';
    }
    return null;
  }
}
