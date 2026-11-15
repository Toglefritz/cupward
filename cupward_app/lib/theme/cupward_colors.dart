import 'package:material_ui/material_ui.dart';

/// Fixed, app-specific colors that do not map onto a Material [ColorScheme] role.
///
/// Registered on [ThemeData.extensions] so they are read through the theme, for example
/// `context.theme.extension<CupwardColors>()` or the `context.cupwardColors` shortcut.
@immutable
class CupwardColors extends ThemeExtension<CupwardColors> {
  /// Creates a set of app-specific colors.
  const CupwardColors({required this.accent, required this.success, required this.cardBorder});

  /// The warm copper accent, used for eyebrow labels such as "STEP 1 OF 6" and for active markers.
  final Color accent;

  /// Indicates a healthy state, such as a connected scale.
  final Color success;

  /// Hairline border color used around cards and panels, and between rows inside a section.
  final Color cardBorder;

  /// Colors for the app's theme.
  static const CupwardColors light = CupwardColors(
    accent: Color(0xFFD29A6E),
    success: Color(0xFF1F4D32),
    cardBorder: Color(0xFFE6DACB),
  );

  @override
  CupwardColors copyWith({Color? accent, Color? success, Color? cardBorder}) {
    return CupwardColors(
      accent: accent ?? this.accent,
      success: success ?? this.success,
      cardBorder: cardBorder ?? this.cardBorder,
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
    );
  }
}
