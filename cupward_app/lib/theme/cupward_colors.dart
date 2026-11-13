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
    required this.brandGradient,
    required this.scale,
    required this.scaleEdge,
  });

  /// Warm orange used for eyebrow labels such as "STEP 1 OF 6" and the active step marker.
  final Color accent;

  /// Indicates a healthy state, such as a connected scale.
  final Color success;

  /// Hairline border color used around cards and panels.
  final Color cardBorder;

  /// Gradient used by prominent brand-colored surfaces like the primary action button.
  final Gradient brandGradient;

  /// Top surface color of the scale illustration.
  final Color scale;

  /// Edge highlight color of the scale illustration.
  final Color scaleEdge;

  /// Colors for the light theme.
  static const CupwardColors light = CupwardColors(
    accent: Color(0xFFB5651D),
    success: Color(0xFF22B04B),
    cardBorder: Color(0xFFEFE0D0),
    brandGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFB0653A), Color(0xFF86441C)],
    ),
    scale: Color(0xFF8A6A52),
    scaleEdge: Color(0xFFEAD8C4),
  );

  /// Colors for the dark theme.
  static const CupwardColors dark = CupwardColors(
    accent: Color(0xFFE09A5B),
    success: Color(0xFF4CD27A),
    cardBorder: Color(0xFF3D2C22),
    brandGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFD08A55), Color(0xFFA9622F)],
    ),
    scale: Color(0xFF6B523F),
    scaleEdge: Color(0xFF8C7260),
  );

  @override
  CupwardColors copyWith({
    Color? accent,
    Color? success,
    Color? cardBorder,
    Gradient? brandGradient,
    Color? scale,
    Color? scaleEdge,
  }) {
    return CupwardColors(
      accent: accent ?? this.accent,
      success: success ?? this.success,
      cardBorder: cardBorder ?? this.cardBorder,
      brandGradient: brandGradient ?? this.brandGradient,
      scale: scale ?? this.scale,
      scaleEdge: scaleEdge ?? this.scaleEdge,
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
      brandGradient: Gradient.lerp(brandGradient, other.brandGradient, t)!,
      scale: Color.lerp(scale, other.scale, t)!,
      scaleEdge: Color.lerp(scaleEdge, other.scaleEdge, t)!,
    );
  }
}
