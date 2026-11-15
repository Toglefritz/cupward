import 'package:material_ui/material_ui.dart';

/// Fixed, app-specific colors that do not map onto a Material [ColorScheme] role.
///
/// Registered on [ThemeData.extensions] so they are read through the theme, for example
/// `context.theme.extension<CupwardColors>()` or the `context.cupwardColors` shortcut.
@immutable
class CupwardColors extends ThemeExtension<CupwardColors> {
  /// Creates a set of app-specific colors.
  const CupwardColors({
    required this.accent,
    required this.success,
    required this.cardBorder,
    required this.cardSurface,
    required this.creamGradient,
  });

  /// The warm copper accent, used for eyebrow labels such as "STEP 1 OF 6" and for active markers.
  final Color accent;

  /// Indicates a healthy state, such as a connected scale.
  final Color success;

  /// Hairline border color used around cards and panels, and between rows inside a section.
  final Color cardBorder;

  /// The fill of cards and panels, a cream slightly lighter than the page so a card reads as a raised surface.
  final Color cardSurface;

  /// The fill of cream, pill-shaped buttons, such as the actions inside the app's cards.
  ///
  /// It runs from a light cream at the top to a warmer cream at the bottom, which gives the button some depth. Text and
  /// icons on it use the ink color, `ColorScheme.onSurface`.
  final Gradient creamGradient;

  /// Colors for the app's theme.
  static const CupwardColors light = CupwardColors(
    accent: Color(0xFFD29A6E),
    success: Color(0xFF1F4D32),
    cardBorder: Color(0xFFE6DACB),
    cardSurface: Color(0xFFFCF7F0),
    creamGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[Color(0xFFFCF6EE), Color(0xFFEBD9BF)],
    ),
  );

  @override
  CupwardColors copyWith({
    Color? accent,
    Color? success,
    Color? cardBorder,
    Color? cardSurface,
    Gradient? creamGradient,
  }) {
    return CupwardColors(
      accent: accent ?? this.accent,
      success: success ?? this.success,
      cardBorder: cardBorder ?? this.cardBorder,
      cardSurface: cardSurface ?? this.cardSurface,
      creamGradient: creamGradient ?? this.creamGradient,
    );
  }

  @override
  CupwardColors lerp(ThemeExtension<CupwardColors>? other, double t) {
    if (other is! CupwardColors) {
      return this;
    }

    return CupwardColors(
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      creamGradient: Gradient.lerp(creamGradient, other.creamGradient, t)!,
    );
  }
}
