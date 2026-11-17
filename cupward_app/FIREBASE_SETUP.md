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
   flutterfire configure --project=cupward-2b4bc --platforms=android,ios,macos,web
   ```

   When prompted, accept the existing app registrations for each platform. This creates all five files listed above.

4. Fetch dependencies and confirm the build:

   ```sh
   flutter pub get
   flutter analyze
   flutter run
   ```

## Anonymous sign-in

The app signs in to Firebase Authentication anonymously at launch, without asking the user for anything, so that their data can be stored under their own user ID. The Anonymous provider must be turned on for the project, in the Firebase console under **Security**, then **Authentication**, then **Sign-in method**. While it is off, sign-in fails with `operation-not-allowed`, which the app logs.

Leave the automatic clean-up of anonymous accounts turned off. It deletes anonymous accounts older than 30 days, including ones that are still in use, along with the user's access to their data.

## App Check on the web

App Check protects Firebase AI Logic, so the browser needs a provider too.

- **Debug builds** use the web debug provider. On the first run, the browser's developer console prints an App Check debug token. Register it in the Firebase console under **Security**, then **App Check**, then **Apps**, by choosing **Manage debug tokens** on the web app.
- **Release builds** use reCAPTCHA Enterprise. Create a reCAPTCHA Enterprise key for the app's domain, register it for the web app in the App Check console, and pass the site key at build time:

  ```sh
  flutter build web --dart-define=RECAPTCHA_SITE_KEY=<site-key>
  ```

  Without the site key, a release build does not activate App Check in the browser, and requests to services that enforce App Check are rejected.

## Notes

- Never commit service account keys (for example `*-firebase-adminsdk-*.json`). These are real secrets and are ignored by `.gitignore`.
- Adding a new platform requires re-running `flutterfire configure` with that platform included. List every platform in the command, because the generated `firebase_options.dart` only covers the platforms named in it.
