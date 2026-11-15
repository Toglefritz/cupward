/// The app's custom icons, each with the path of its image in the assets.
///
/// Views refer to icons through this enum instead of using asset paths directly, so an icon can be replaced, or a
/// placeholder swapped for the final artwork, by changing its path here. Icons that Material already provides, such as
/// the back arrow, use `Icons` instead and are not listed.
///
/// The images live in `assets/icons/`. That directory must be listed under `flutter: assets:` in `pubspec.yaml` once it
/// holds the files, because the existing `assets/` entry only includes files at the top level of `assets/`.
enum AppIcon {
  /// Coffee beans, for the coffee dose of a recipe.
  coffee('assets/icons/beans.png'),

  /// A water drop, for the water weight of a recipe.
  water('assets/icons/water.png'),

  /// A clock, for the brew time of a recipe.
  brewTime('assets/icons/brew_time.png'),

  /// A cup, for the yield of a recipe.
  brewYield('assets/icons/brew_yield.png');

  /// Creates an icon whose image is at [path].
  const AppIcon(this.path);

  /// The path of the icon's image, relative to the app's root, as passed to `Image.asset`.
  final String path;
}
