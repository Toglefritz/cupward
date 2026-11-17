# Cupward Cloud

Firebase project resources for Cupward that live alongside the Flutter app in `cupward_app`: the Cloud Firestore
security rules and indexes, and the Firebase Emulator Suite configuration and tooling.

Project: `cupward-2b4bc` (see `.firebaserc`).

## Prerequisites

- [Node.js](https://nodejs.org) and the Firebase CLI: `npm install -g firebase-tools`
- `firebase login` with an account that has access to the project
- Java (required by the Firestore emulator)

## Running the Emulator Suite

From this directory:

```sh
./firebase_emulator_suite.command
```

Or double-click the file in Finder. Emulator state is imported from `emulator_data/` when it exists.

- **Ctrl+X** stops the emulators and exports state to `emulator_data/`.
- **Ctrl+C** stops the emulators without saving state.
- `./firebase_emulator_suite.command stop` exports state from emulators started elsewhere.

| Emulator | Port |
| --- | --- |
| Authentication | 9099 |
| Firestore | 8080 |
| Emulator UI | 4000 |

## Pointing the app at the emulators

Debug builds of the app connect to the emulators only when launched with the `USE_FIREBASE_EMULATOR` flag:

```sh
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

Desktop and iOS simulator builds reach the emulators at `localhost`, Android emulators at `10.0.2.2`. For a physical
device, pass the development machine's LAN IP:

```sh
flutter run --dart-define=USE_FIREBASE_EMULATOR=true --dart-define=EMULATOR_HOST=192.168.1.20
```

With the flag, Firebase Authentication and Cloud Firestore use the emulators. Firebase AI Logic has no emulator, so AI
requests still reach the cloud.

## Cloud Firestore

The app reads and writes Firestore directly through the `cloud_firestore` plugin, with no server code in between. The
security rules in [`firestore.rules`](firestore.rules) are therefore the only check on what a client can do, and they
deny everything they do not allow.

| Path | Holds | Access |
| --- | --- | --- |
| `users/{userId}/recipes/{recipeId}` | One brew recipe | Only the signed-in user whose ID is `userId` |

The user ID comes from Firebase Authentication, where the app signs in anonymously. The recipe ID is derived from the
recipe's name, so each of a user's recipes has a unique name. The rules also check each recipe's fields and values, and
that `createdAt` and `updatedAt` are set by the server.

The emulator loads the rules from this directory. Deploy them to the project after changing them:

```sh
firebase deploy --only firestore:rules,firestore:indexes
```

## Firebase App Check

App Check has no emulator. Debug builds use the App Check debug provider, which prints a debug token on first launch.
Register that token in the Firebase console under **App Check > Apps > Manage debug tokens** so requests from your
development builds are accepted once enforcement is enabled.
