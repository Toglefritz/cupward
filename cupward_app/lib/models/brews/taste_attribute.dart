/// A property of a cup of coffee that the user rates after a brew.
///
/// Each attribute is rated on the same scale in `TastingNotes`, from none or very little to a lot, except [overall],
/// which rates how much the user enjoyed the cup. The attributes
/// are the ones that brewing changes most directly, so brew feedback can relate each rating to the recipe and the
/// readings from the scale.
///
/// The [name] of each value is its JSON form, so values must not be renamed.
enum TasteAttribute {
  /// How strong and concentrated the cup tastes, from weak and watery to strong.
  intensity,

  /// How bright or sour the cup tastes, from flat to sharp.
  acidity,

  /// How sweet the cup tastes.
  sweetness,

  /// How bitter the cup tastes.
  bitterness,

  /// How heavy the cup feels in the mouth, from thin to syrupy.
  body,

  /// How dry and puckering the finish feels, from smooth to chalky.
  astringency,

  /// How much the user enjoyed the cup.
  overall;

  /// Returns the attribute whose [name] is [value].
  ///
  /// Throws an [ArgumentError] if no attribute has that name, for example in data written by a newer version of the
  /// app.
  static TasteAttribute fromName(String value) {
    for (final TasteAttribute attribute in values) {
      if (attribute.name == value) {
        return attribute;
      }
    }
    throw ArgumentError('Unknown taste attribute: $value');
  }
}
