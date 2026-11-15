/// The illustrations shown in the middle of the brewing screen, one for each step of a pour over, with the path of each
/// image in the assets.
///
/// Like `AppIcon`, views refer to these images through the enum instead of using asset paths directly, so an image can
/// be replaced by changing its path here. The images are 1342 by 1172 pixel PNGs in `assets/brew_steps/`, which
/// `pubspec.yaml` lists as an asset directory, and are drawn on a transparent background so that the page shows
/// through.
///
/// The images show a pour over, so they suit the phases of a pour over recipe. Other brewing methods will need their
/// own illustrations.
enum BrewStepImage {
  /// An empty dripper and server on the scale, ready to be tared.
  prepare('assets/brew_steps/prepare_to_brew.png'),

  /// Grounds wetted for the bloom.
  bloom('assets/brew_steps/bloom.png'),

  /// The first of the main pours.
  pour1('assets/brew_steps/pour1.png'),

  /// The second of the main pours.
  pour2('assets/brew_steps/pour2.png'),

  /// The third of the main pours, which also serves for any later pours.
  pour3('assets/brew_steps/pour3.png'),

  /// The finished brew.
  complete('assets/brew_steps/brew_complete.png');

  /// Creates an image whose file is at [path].
  const BrewStepImage(this.path);

  /// The path of the image, relative to the app's root, as passed to `Image.asset`.
  final String path;

  /// The width of the images divided by their height, so they can be laid out before they load.
  static const double aspectRatio = 1342 / 1172;
}
