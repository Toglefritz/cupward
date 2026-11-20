/// The illustrations shown in the middle of the brewing screen, one for each step of a brew, with the path of each
/// image in the assets.
///
/// Each brewing method has its own set, named for the method and the step, such as `chemexBloom`. The V60 set also
/// serves the Kalita Wave, which looks much the same in this style. `BrewPhaseLabels.imageFor` chooses the image for
/// a phase of a recipe.
///
/// Like `AppIcon`, views refer to these images through the enum instead of using asset paths directly, so an image can
/// be replaced by changing its path here. The images are PNGs in `assets/brew_steps/`, which `pubspec.yaml` lists as an
/// asset directory, and are drawn on a transparent background so that the page shows through. They are about 1300 by
/// 1200 pixels, and the brewing screen fits each one inside a box of [aspectRatio], so a step change never moves the
/// layout even where an image's own proportions differ.
enum BrewStepImage {
  // V60 and Kalita Wave

  /// An empty V60 dripper and server on the scale, ready to be tared.
  v60Prepare('assets/brew_steps/v60_prepare.png'),

  /// Grounds wetted for the bloom.
  v60Bloom('assets/brew_steps/v60_bloom.png'),

  /// The first of the main pours.
  v60Pour1('assets/brew_steps/v60_pour1.png'),

  /// The second of the main pours.
  v60Pour2('assets/brew_steps/v60_pour2.png'),

  /// The third of the main pours, which also serves for any later pours.
  v60Pour3('assets/brew_steps/v60_pour3.png'),

  /// The finished V60 brew.
  v60Complete('assets/brew_steps/v60_complete.png'),

  // Chemex

  /// An empty Chemex with its filter on the scale, ready to be tared.
  chemexPrepare('assets/brew_steps/chemex_prepare.png'),

  /// Grounds wetted for the bloom.
  chemexBloom('assets/brew_steps/chemex_bloom.png'),

  /// The first of the main pours.
  chemexPour1('assets/brew_steps/chemex_pour1.png'),

  /// The second of the main pours, which also serves for any later pours.
  chemexPour2('assets/brew_steps/chemex_pour2.png'),

  /// The finished Chemex brew.
  chemexComplete('assets/brew_steps/chemex_complete.png'),

  // French Press

  /// An empty French press on the scale, ready to be tared.
  frenchPressPrepare('assets/brew_steps/french_press_prepare.png'),

  /// The press, with its lid off, filled with water and grounds.
  frenchPressPour1('assets/brew_steps/french_press_pour1.png'),

  /// The press full of steaming coffee and grounds, steeping.
  frenchPressSteep('assets/brew_steps/french_press_steep.png'),

  /// The plunger pressed down on the finished French press brew.
  frenchPressComplete('assets/brew_steps/french_press_complete.png'),

  // AeroPress

  /// An empty AeroPress on a mug on the scale, ready to be tared.
  aeroPressPrepare('assets/brew_steps/aeropress_prepare.png'),

  /// The AeroPress chamber partly filled with water and grounds.
  aeroPressPour1('assets/brew_steps/aeropress_pour1.png'),

  /// The chamber full of steaming coffee and grounds, steeping.
  aeroPressSteep('assets/brew_steps/aeropress_steep.png'),

  /// A mug of the finished AeroPress brew.
  aeroPressComplete('assets/brew_steps/aeropress_complete.png'),

  // Clever Dripper

  /// An empty Clever Dripper with its filter, on a mug on the scale, ready to be tared.
  cleverDripperPrepare('assets/brew_steps/clever_dripper_prepare.png'),

  /// The dripper partly filled with water and grounds.
  cleverDripperPour1('assets/brew_steps/clever_dripper_pour1.png'),

  /// The dripper full of steaming coffee and grounds, steeping.
  cleverDripperSteep('assets/brew_steps/clever_dripper_steep.png'),

  /// A mug of the finished Clever Dripper brew.
  cleverDripperComplete('assets/brew_steps/clever_dripper_complete.png');

  /// Creates an image whose file is at [path].
  const BrewStepImage(this.path);

  /// The path of the image, relative to the app's root, as passed to `Image.asset`.
  final String path;

  /// The width of the images divided by their height, so they can be laid out before they load.
  static const double aspectRatio = 1342 / 1172;
}
