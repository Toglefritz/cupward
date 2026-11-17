part of '../app.dart';

/// Provides theme configuration for the application.
///
/// The look is warm paper, dark ink, and a deep green accent, with DM Serif Display for headline figures and IBM Plex
/// Mono for live values. Both fonts are bundled under `assets/fonts`, so nothing is fetched at run time.
///
/// Widgets read everything here through `context.theme`. The text theme assigns each role to one kind of content, so
/// this mapping is the reference for which style to use:
///
/// | Role | Font | Used for |
/// | --- | --- | --- |
/// | `displayLarge` | Serif | The main figure on a screen, such as a live weight |
/// | `headlineLarge` | Serif | Screen titles |
/// | `headlineMedium` | Serif | A unit beside the main figure |
/// | `headlineSmall` | Mono | Secondary live values, such as flow rate and time |
/// | `titleLarge` | Sans, semibold | Section headings |
/// | `titleMedium` | Sans | Status lines and labels |
/// | `bodyLarge` | Sans | Running text, such as log messages and responses |
/// | `bodyMedium` | Sans | Captions and hints |
/// | `labelLarge` | Sans, semibold | Primary buttons |
/// | `labelMedium` | Sans, spaced | The subtitle under a screen title |
/// | `labelSmall` | Mono | Timestamps and other small readouts |
///
/// SnackBars float above the content as small cream cards with ink text. `AppSnackBars` builds them with an icon that
/// says whether the message confirms something or reports a problem.
class _AppTheme {
  /// The family name of the bundled display serif, as declared in pubspec.yaml.
  static const String _serif = 'DM Serif Display';

  /// The family name of the bundled monospace face, as declared in pubspec.yaml.
  static const String _mono = 'IBM Plex Mono';

  /// Background paper.
  static const Color _paper = Color(0xFFF8F0E5);

  /// Primary text.
  static const Color _ink = Color(0xFF1C1B19);

  /// Secondary text.
  static const Color _mutedInk = Color(0xFF6B655C);

  /// Accent for actions and healthy states, such as a connected scale.
  static const Color _green = Color(0xFF1F4D32);

  /// Rules between major sections.
  static const Color _copper = Color(0xFFD29A6E);

  /// Rules between rows inside a section, and idle status indicators.
  static const Color _hairline = Color(0xFFE6DACB);

  /// In-progress status indicators.
  static const Color _amber = Color(0xFFC98A2B);

  /// Errors.
  static const Color _red = Color(0xFFA63A2B);

  /// The theme used by the app.
  static ThemeData get light {
    const ColorScheme colors = ColorScheme(
      brightness: Brightness.light,
      primary: _green,
      onPrimary: Colors.white,
      secondary: _green,
      onSecondary: Colors.white,
      tertiary: _amber,
      onTertiary: Colors.white,
      error: _red,
      onError: Colors.white,
      surface: _paper,
      onSurface: _ink,
      onSurfaceVariant: _mutedInk,
      outline: _copper,
      outlineVariant: _hairline,
    );

    final TextTheme base = ThemeData(brightness: Brightness.light).textTheme.apply(bodyColor: _ink, displayColor: _ink);

    final TextTheme text = base.copyWith(
      displayLarge: const TextStyle(
        fontFamily: _serif,
        fontSize: 112,
        height: 1,
        color: _ink,
        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
      ),
      headlineLarge: const TextStyle(
        fontFamily: _serif,
        fontSize: 48,
        height: 1.05,
        color: _ink,
      ),
      headlineMedium: const TextStyle(
        fontFamily: _serif,
        fontSize: 40,
        height: 1,
        color: _ink,
      ),
      headlineSmall: const TextStyle(
        fontFamily: _mono,
        fontSize: 28,
        height: 1.2,
        color: _ink,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w400,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 15, color: _ink),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 16,
        letterSpacing: 1.6,
        color: _ink,
      ),
      labelSmall: const TextStyle(
        fontFamily: _mono,
        fontSize: 13,
        letterSpacing: 0.4,
        color: _mutedInk,
      ),
    );

    return ThemeData(
      colorScheme: colors,
      scaffoldBackgroundColor: _paper,
      textTheme: text,
      extensions: const <ThemeExtension<dynamic>>[CupwardColors.light],
      dividerTheme: const DividerThemeData(
        color: _copper,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: _green),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _green.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(68),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      // Short messages float above the content as small cream cards, matching the app's cards, rather than Material's
      // dark bar along the bottom.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CupwardColors.light.cardSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: _ink, fontWeight: FontWeight.w600),
        actionTextColor: _green,
        elevation: 3,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: CupwardColors.light.cardBorder),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _green,
          textStyle: text.titleMedium?.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: _green,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(0, 40),
        ),
      ),
    );
  }
}
