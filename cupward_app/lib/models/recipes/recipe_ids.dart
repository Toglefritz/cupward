/// Derives a recipe's ID from its name, which is how each of a user's recipes gets a unique name.
///
/// A recipe is stored under its ID, so two recipes whose names give the same ID cannot both exist. The ID keeps the
/// letters and digits of the name in lowercase, in any script, and joins the words with hyphens, so "V60 Pour Over"
/// becomes `v60-pour-over`. Names that differ only in case, spacing, or punctuation, such as "V60 pour-over", give the
/// same ID and so count as the same name.
abstract final class RecipeIds {
  /// The longest an ID can be. It keeps the IDs readable in the Firebase console, and matches the security rules.
  static const int maxLength = 60;

  /// The ID used when a name has no letters or digits at all.
  static const String fallback = 'recipe';

  /// Characters that are not letters or digits in any script.
  static final RegExp _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  /// A letter or digit in any script.
  static final RegExp _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// Returns the ID for a recipe named [name].
  static String fromName(String name) {
    String id = name.toLowerCase().replaceAll(_separators, '-');
    id = _trimHyphens(id);
    if (id.length > maxLength) {
      id = _trimHyphens(_shorten(id));
    }
    return id.isEmpty ? fallback : id;
  }

  /// Whether [name] has at least one letter or digit, so that it gives an ID of its own rather than [fallback].
  ///
  /// A name of only symbols, such as "☕", would share the fallback ID with every other such name, and a numbered copy
  /// of it, such as "☕ 2", would get an ID of just the number.
  static bool hasLettersOrDigits(String name) => _letterOrDigit.hasMatch(name);

  /// Returns the longest start of [id] that fits in [maxLength] UTF-16 code units without splitting a character
  /// outside the Basic Multilingual Plane, whose two halves would not be valid in a Firestore document ID.
  static String _shorten(String id) {
    final StringBuffer buffer = StringBuffer();
    int length = 0;
    for (final int rune in id.runes) {
      final int size = rune > 0xFFFF ? 2 : 1;
      if (length + size > maxLength) {
        break;
      }
      buffer.writeCharCode(rune);
      length += size;
    }
    return buffer.toString();
  }

  /// Removes hyphens from both ends of [value].
  static String _trimHyphens(String value) => value.replaceAll(RegExp(r'^-+|-+$'), '');
}
