import '../messages.g.dart';

/// Converts the string returned by Chrome's `LanguageModel.availability()` into an [OnDeviceModelAvailability].
///
/// Chrome reports `available`, `downloadable`, `downloading`, or `unavailable`. A null [value] means the browser
/// does not expose the `LanguageModel` global at all, which is the case for browsers without the Prompt API. Any
/// value this plugin does not recognize is treated as unavailable, because it cannot be assumed to be usable.
OnDeviceModelAvailability parseChromeAvailability(String? value) {
  switch (value) {
    case 'available':
      return OnDeviceModelAvailability.available;
    case 'downloadable':
      return OnDeviceModelAvailability.downloadable;
    case 'downloading':
      return OnDeviceModelAvailability.downloading;
    default:
      return OnDeviceModelAvailability.unavailable;
  }
}
