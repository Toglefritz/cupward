# Firebase Setup

The example app connects to a Firebase project that you own. The files that link the app to that project are generated per developer and are **not committed** to Git. After cloning, generate them before running the app.

## Files you need to generate

| File | Used by |
| --- | --- |
| `lib/firebase_options.dart` | Dart code (`Firebase.initializeApp`) |
| `firebase.json` | FlutterFire CLI configuration |
| `android/app/google-services.json` | Android |
| `ios/Runner/GoogleService-Info.plist` | iOS |

All of these are listed in `.gitignore`. Do not remove them from it, and do not commit them.

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) installed and on your `PATH`.
- [Node.js](https://nodejs.org), which the Firebase CLI requires.
- A Firebase project. Create one in the [Firebase console](https://console.firebase.google.com) if you do not have one. The example does not need Google Analytics.

## Steps

1. Install the Firebase CLI and sign in:

   ```sh
   npm install -g firebase-tools
   firebase login
   ```

2. Install the FlutterFire CLI:

   ```sh
   dart pub global activate flutterfire_cli
   ```

   Make sure `~/.pub-cache/bin` is on your `PATH`.

3. From the `example` directory, generate the configuration files for your project:

   ```sh
   cd example
   flutterfire configure --project=<your-firebase-project-id> --platforms=android,ios,web
   ```

   When prompted, register new apps for each platform. This creates all of the files listed above.

4. Fetch dependencies and confirm the build:

   ```sh
   flutter pub get
   flutter analyze
   ```

## Running on a device

Checking the on-device model status does not contact Firebase servers, so it works with any project and without a network connection. The platforms have these requirements:

- **Android:** a device that supports on-device Gemini Nano through the ML Kit Prompt API. See the [supported devices](https://developers.google.com/ml-kit/genai#prompt-device). Emulators cannot run on-device models, and the status reads as unavailable.
- **Web:** desktop Chrome with the Prompt API enabled. Chrome's [requirements](https://developer.chrome.com/docs/ai/prompt-api#requirements) cover the operating system, storage, and GPU or CPU. Set the `chrome://flags/#prompt-api-for-gemini-nano-multimodal-input` flag to Enabled and restart Chrome.

## Notes

- Never commit service account keys (for example `*-firebase-adminsdk-*.json`). These are real secrets and are ignored by `.gitignore`.
- Adding a platform later requires running `flutterfire configure` again with that platform included.
