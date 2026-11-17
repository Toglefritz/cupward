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

  /// Returns the ID for a recipe named [name].
  static String fromName(String name) {
    String id = name.toLowerCase().replaceAll(_separators, '-');
    id = _trimHyphens(id);
    if (id.length > maxLength) {
      id = _trimHyphens(id.substring(0, maxLength));
    }
    return id.isEmpty ? fallback : id;
  }

  /// Removes hyphens from both ends of [value].
  static String _trimHyphens(String value) => value.replaceAll(RegExp(r'^-+|-+$'), '');
}
