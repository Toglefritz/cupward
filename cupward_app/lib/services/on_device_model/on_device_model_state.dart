/// Where the app stands with the on-device AI model.
///
/// Brew feedback uses Firebase AI Logic's hybrid inference, which runs on the device when it can and falls back to the
/// cloud otherwise. So every state allows feedback. The state only says whether it can come from the device.
enum OnDeviceModelState {
  /// The app has not checked yet, or is checking now.
  checking,

  /// The model is installed and ready.
  available,

  /// The model can be downloaded but is not installed.
  downloadable,

  /// The model is downloading.
  downloading,

  /// The device or browser cannot run an on-device model, so feedback always comes from the cloud.
  unavailable,

  /// The check failed, so the app does not know whether the device can run the model. It can check again.
  unknown,
}
