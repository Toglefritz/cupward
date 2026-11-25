/// Decides from the address the app was opened with whether it should start in demo mode.
///
/// Opening the web app with `?demo=true`, for example `https://cupward-2b4bc.web.app/?demo=true`, starts it with the
/// simulated scale already connected, so a visitor does not have to choose "Start demo" from the menu on the brewing
/// screen. The menu still ends the demo.
abstract final class DemoLaunch {
  /// The name of the query parameter that asks for demo mode.
  static const String parameter = 'demo';

  /// Whether [address] asks for demo mode: it has a `demo` query parameter with no value, or with a value of `true`
  /// or `1`, in any letter case. Any other value, such as `false`, leaves demo mode off.
  static bool isRequested(Uri address) {
    final String? value = address.queryParameters[parameter];
    if (value == null) {
      return false;
    }
    final String normalized = value.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'true' || normalized == '1';
  }
}
