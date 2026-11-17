/// Why signing in failed.
enum AuthFailure {
  /// Anonymous sign-in is turned off for the Firebase project, so no request can succeed until it is turned on in the
  /// Firebase console.
  disabled,

  /// The device could not reach Firebase, for example because it is offline. A later attempt may succeed.
  network,

  /// Any other failure.
  unknown,
}
