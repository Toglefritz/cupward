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

  // V60 and Kalita Wave

  /// An empty dripper and server on the scale, ready to be tared.
  v60Prepare('assets/brew_steps/v60_prepare.png'),

  /// Grounds wetted for the bloom.
  v60Bloom('assets/brew_steps/v60_bloom.png'),

  /// The first of the main pours.
  v60Pour1('assets/brew_steps/v60_pour1.png'),

  /// The second of the main pours.
  v60Pour2('assets/brew_steps/v60_pour2.png'),

  /// The third of the main pours, which also serves for any later pours.
  v60Pour3('assets/brew_steps/v60Pour3.png'),

  /// The finished V60 brew.
  v60Complete('assets/brew_steps/v60_complete.png'),

  // Chemex

  /// An empty carafe on the scale, ready to be tared.
  chemexPrepare('assets/brew_steps/chemex_prepare.png'),

  /// Grounds wetted for the bloom.
  chemexBloom('assets/brew_steps/chemex_bloom.png'),

  /// The first of the main pours.
  chemexPour1('assets/brew_steps/chemex_pour1.png'),

  /// The second of the main pours.
  chemexPour2('assets/brew_steps/chemex_pour2.png'),

  /// The finished Chemex brew.
  chemexComplete('assets/brew_steps/chemex_complete.png'),

  // French Press

  /// An empty carafe on the scale, ready to be tared.
  frenchPressPrepare('assets/brew_steps/french_press_prepare.png'),

  /// The carafe half filled with water.
  frenchPressPour1('assets/brew_steps/french_press_pour1.png'),

  /// The carafe filled with a mix of water and coffee grounds.
  frenchPressSteep('assets/brew_steps/french_press_steep.png'),

  /// The finished French Press brew.
  frenchPressComplete('assets/brew_steps/french_press_complete.png'),

  // Aero Press

  /// An empty carafe on the scale, ready to be tared.
  aeroPressPrepare('assets/brew_steps/aeropress_prepare.png'),

  /// The first of the main pours.
  aeroPressPour1('assets/brew_steps/aeropress_pour1.png'),

  /// The carafe filled with a mix of water and coffee grounds.
  aeroPressSteep('assets/brew_steps/aeropress_steep.png'),

  /// The finished Aero Press brew.
  aeroPressComplete('assets/brew_steps/aeropress_complete.png'),

  // Clever Dripper

  /// An empty mug on the scale, ready to be tared.
  cleverDripperPrepare('assets/brew_steps/clever_dripper_prepare.png'),

  /// The first of the main pours.
  cleverDripperPour1('assets/brew_steps/clever_dripper_pour1.png'),

  /// The brewer filled with a mix of water and coffee grounds.
  cleverDripperSteep('assets/brew_steps/clever_dripper_steep.png'),

  /// The finished Clever Dripper brew.
  cleverDripperComplete('assets/brew_steps/clever_dripper_complete.png');

  /// Creates an image whose file is at [path].
  const BrewStepImage(this.path);

  /// The path of the image, relative to the app's root, as passed to `Image.asset`.
  final String path;

  /// The width of the images divided by their height, so they can be laid out before they load.
  static const double aspectRatio = 1342 / 1172;
}
