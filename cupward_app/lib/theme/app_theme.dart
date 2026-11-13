part of '../app.dart';

/// Provides theme configuration for the application.
///
/// The look is a warm, coffee-inspired palette: cream surfaces, espresso text, and caramel brown actions, with DM Serif
/// Display used for headings and numeric readouts.
class _AppTheme {
  /// Font family declared in pubspec.yaml for headings and readouts.
  static const String _serifFamily = 'DMSerifDisplay';

  /// Light color scheme: cream background with espresso text and a caramel brown primary.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF9A5428),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF9E1C6),
    onPrimaryContainer: Color(0xFF3A1D0A),
    secondary: Color(0xFF7A5A45),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF9E1C6),
    onSecondaryContainer: Color(0xFF3A1D0A),
    tertiary: Color(0xFFB5651D),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFDF4E9),
    onSurface: Color(0xFF2B1810),
    onSurfaceVariant: Color(0xFF5E4A3E),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFF9F2),
    surfaceContainer: Color(0xFFFBEFE1),
    surfaceContainerHigh: Color(0xFFF7E8D6),
    surfaceContainerHighest: Color(0xFFF2E0CB),
    outline: Color(0xFFC9AE97),
    outlineVariant: Color(0xFFE6D3C0),
    shadow: Color(0xFF2B1810),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF3A2A20),
    onInverseSurface: Color(0xFFFDF4E9),
    inversePrimary: Color(0xFFE6A878),
  );

  /// Dark color scheme: roasted espresso surfaces with a lightened caramel primary.
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFE0955B),
    onPrimary: Color(0xFF3A1D0A),
    primaryContainer: Color(0xFF5A3219),
    onPrimaryContainer: Color(0xFFF9E1C6),
    secondary: Color(0xFFD2B49C),
    onSecondary: Color(0xFF38281D),
    secondaryContainer: Color(0xFF4A3426),
    onSecondaryContainer: Color(0xFFF9E1C6),
    tertiary: Color(0xFFE09A5B),
    onTertiary: Color(0xFF3A1D0A),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    surface: Color(0xFF1C130E),
    onSurface: Color(0xFFF6E8D8),
    onSurfaceVariant: Color(0xFFCDB8A5),
    surfaceContainerLowest: Color(0xFF150D09),
    surfaceContainerLow: Color(0xFF241812),
    surfaceContainer: Color(0xFF2A1D16),
    surfaceContainerHigh: Color(0xFF342419),
    surfaceContainerHighest: Color(0xFF3F2E22),
    outline: Color(0xFF8C7260),
    outlineVariant: Color(0xFF4A3A2E),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF6E8D8),
    onInverseSurface: Color(0xFF2B1810),
    inversePrimary: Color(0xFF9A5428),
  );

  /// Light theme configuration for the application.
  static ThemeData get lightTheme => _build(_lightScheme, CupwardColors.light);

  /// Dark theme configuration for the application.
  static ThemeData get darkTheme => _build(_darkScheme, CupwardColors.dark);

  /// Builds a complete [ThemeData] from a [scheme] and its matching app-specific [colors].
  static ThemeData _build(ColorScheme scheme, CupwardColors colors) {
    final ThemeData base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final TextTheme textTheme = _textTheme(base.textTheme, scheme);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[colors],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.cardBorder),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.cardBorder, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(60),
          shape: const StadiumBorder(),
          textStyle: textTheme.titleMedium,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape: const StadiumBorder(),
          textStyle: textTheme.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          minimumSize: const Size(0, 52),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary, shape: const StadiumBorder()),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
      ),
    );
  }

  /// Applies DM Serif Display to headings, titles, and numeric readouts while keeping the platform font for body and
  /// label text. Colors come from the [scheme] so both brightness modes stay consistent.
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle? serif(TextStyle? style) => style?.copyWith(fontFamily: _serifFamily, fontWeight: FontWeight.w400);

    final TextTheme colored = base.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return colored.copyWith(
      displayLarge: serif(colored.displayLarge),
      displayMedium: serif(colored.displayMedium),
      displaySmall: serif(colored.displaySmall),
      headlineLarge: serif(colored.headlineLarge),
      headlineMedium: serif(colored.headlineMedium),
      headlineSmall: serif(colored.headlineSmall),
      titleLarge: serif(colored.titleLarge),
      titleMedium: colored.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: colored.bodyLarge?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
      bodyMedium: colored.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: colored.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
