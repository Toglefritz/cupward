# Firebase Setup

Cupward uses Firebase for its cloud services. The files that connect the app to the Firebase project are generated per developer and are **not committed** to Git. After cloning, you must generate them before the app will build.

## Files you need to generate

| File | Used by |
| --- | --- |
| `cupward_app/lib/firebase_options.dart` | Dart code (`Firebase.initializeApp`) |
| `cupward_app/firebase.json` | FlutterFire CLI configuration |
| `cupward_app/android/app/google-services.json` | Android |
| `cupward_app/ios/Runner/GoogleService-Info.plist` | iOS |
| `cupward_app/macos/Runner/GoogleService-Info.plist` | macOS |

All of these are listed in `cupward_app/.gitignore`. Do not remove them from it, and do not commit them.

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) installed and on your `PATH`
- [Node.js](https://nodejs.org) (required by the Firebase CLI)
- Access to the Cupward Firebase project (project ID: `cupward-2b4bc`). 

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

3. From the app directory, generate the configuration files:

   ```sh
   cd cupward_app
   flutterfire configure --project=cupward-2b4bc --platforms=android,ios,macos
   ```

   When prompted, accept the existing app registrations for each platform. This creates all five files listed above.

4. Fetch dependencies and confirm the build:

   ```sh
   flutter pub get
   flutter analyze
   flutter run
   ```

## Notes

- Never commit service account keys (for example `*-firebase-adminsdk-*.json`). These are real secrets and are ignored by `.gitignore`.
- Adding a new platform (such as web) requires re-running `flutterfire configure` with that platform included.
