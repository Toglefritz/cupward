import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_exception.dart';
import 'auth_failure.dart';

/// Signs the user in to Firebase without asking them for anything, so the app can keep their data in Firebase.
///
/// The app signs in anonymously. Firebase gives the install a user ID the first time and keeps the session, so later
/// launches reuse the same ID, and data stored under it, such as recipes, belongs to this user. Nothing is shown to the
/// user. The anonymous account can later be linked to a Google or Apple sign-in, which keeps the same user ID.
///
/// An anonymous account belongs to one install of the app, or one browser on the web. Uninstalling the app or clearing
/// its data loses it, unless it was linked first.
///
/// The app starts signing in at launch without waiting for it, so a launch without a network is not held up. Code that
/// needs the user, such as reading recipes from Firestore, calls [ensureSignedIn], which reuses the session, joins a
/// sign-in that is already running, or tries again after a failure.
class AuthService {
  /// Creates a service.
  ///
  /// [auth] defaults to `FirebaseAuth.instance`. Tests supply their own.
  AuthService({FirebaseAuth? auth}) : _authOverride = auth;

  /// The service that the app shares.
  static final AuthService instance = AuthService();

  /// The Firebase Auth instance supplied by a test, or null to use the app's.
  final FirebaseAuth? _authOverride;

  /// The Firebase Auth instance, read when first needed so that creating the service does not require Firebase.
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  /// The sign-in that is running, or null when none is.
  Future<String>? _pending;

  /// The signed-in user's ID, or null if the app has not signed in yet.
  String? get userId => _auth.currentUser?.uid;

  /// Makes sure the app is signed in, and returns the user's ID.
  ///
  /// Reuses the existing session when there is one. Otherwise signs in anonymously. Calls made while a sign-in is
  /// running wait for it rather than starting another, so the install never ends up with two accounts.
  ///
  /// Throws an [AuthException] if signing in fails. A later call tries again.
  Future<String> ensureSignedIn() {
    return _pending ??= _signIn().whenComplete(() => _pending = null);
  }

  /// Waits for any saved session to be restored, then signs in anonymously if there is none.
  Future<String> _signIn() async {
    // On the web, the saved session is restored after startup. Signing in before it arrives would create a second
    // account, so the first auth state is awaited before deciding.
    final User? restored = _auth.currentUser ?? await _auth.authStateChanges().first;
    if (restored != null) {
      return restored.uid;
    }

    try {
      final UserCredential credential = await _auth.signInAnonymously();
      final User? user = credential.user;
      if (user == null) {
        throw const AuthException(AuthFailure.unknown);
      }
      debugPrint('Signed in anonymously as ${user.uid}');

      return user.uid;
    } on FirebaseAuthException catch (error) {
      debugPrint('Anonymous sign-in failed: ${error.code} ${error.message}');

      throw AuthException(_failureFor(error.code));
    }
  }

  /// The failure that the Firebase Auth error [code] represents.
  static AuthFailure _failureFor(String code) {
    switch (code) {
      case 'operation-not-allowed':
      case 'admin-restricted-operation':
        return AuthFailure.disabled;
      case 'network-request-failed':
        return AuthFailure.network;
      default:
        return AuthFailure.unknown;
    }
  }
}
