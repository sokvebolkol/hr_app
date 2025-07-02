/**
 * App colors
 */

const primary = 0xFF0fbab5;
const secondary = 0xFF052744;

/**
 * App size padding
 */

const appPadding = 16.0;

/**
 * font size label
 */

const labelHeading = 20;
const labelSubHeading = 18;
const labelBody = 16;

// Validation for email address
bool validateEmail(String email) {
  bool isValid = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  ).hasMatch(email);
  return isValid;
}

// Function to check if the input contains a number
bool isNumber(String input) {
  final numberRegex = RegExp(r'^[0-9]+$');
  return numberRegex.hasMatch(input);
}

// Function to check if the input contains an emoji
bool isEmoji(String input) {
  final emojiRegex = RegExp(
    r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
    unicode: true,
  );
  return emojiRegex.hasMatch(input);
}

enum LoadingStatus { none, loading, error, done }
