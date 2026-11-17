import 'dart:async';

import 'package:cupward/services/auth/auth_exception.dart';
import 'package:cupward/services/auth/auth_failure.dart';
import 'package:cupward/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// A signed-in user with an ID.
class _FakeUser implements User {
  /// Creates a user with [uid].
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The result of a sign-in.
class _FakeCredential implements UserCredential {
  /// Creates a credential for [user].
  _FakeCredential(this.user);

  @override
  final User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A Firebase Auth stand-in whose session, restored state, and sign-in result the test controls.
class _FakeAuth implements FirebaseAuth {
  /// The user available at once, as on Android and iOS after a previous launch.
  User? signedIn;

  /// The first auth state, delivered after startup, as on the web after the saved session is restored.
  User? restored;

  /// What the next sign-in throws, or null to succeed.
  FirebaseAuthException? signInError;

  /// When set, sign-ins wait for it, so a test can make overlapping calls.
  Completer<void>? gate;

  /// How many times [signInAnonymously] was called.
  int signInCount = 0;

  @override
  User? get currentUser => signedIn;

  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(signedIn ?? restored);

  @override
  Future<UserCredential> signInAnonymously() async {
    signInCount++;
    await gate?.future;
    final FirebaseAuthException? error = signInError;
    if (error != null) {
      throw error;
    }
    final User user = _FakeUser('anonymous-$signInCount');
    signedIn = user;
    return _FakeCredential(user);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Verifies that the app reuses its session, signs in anonymously only when it has none, and reports failures.
void main() {
  late _FakeAuth auth;
  late AuthService service;

  setUp(() {
    auth = _FakeAuth();
    service = AuthService(auth: auth);
  });

  /// Returns the failure that [request] ends with.
  Future<AuthFailure> failureOf(Future<String> request) async {
    try {
      await request;
    } on AuthException catch (error) {
      return error.failure;
    }
    fail('The sign-in was expected to fail.');
  }

  group('AuthService', () {
    /// A returning user keeps their ID, and with it their data.
    test('reuses the existing session', () async {
      // Arrange
      auth.signedIn = _FakeUser('returning');

      // Act
      final String userId = await service.ensureSignedIn();

      // Assert
      expect(userId, 'returning');
      expect(auth.signInCount, 0);
    });

    /// On the web the session arrives after startup, and signing in before it would create a second account.
    test('waits for a restored session before signing in', () async {
      // Arrange
      auth.restored = _FakeUser('restored');

      // Act
      final String userId = await service.ensureSignedIn();

      // Assert
      expect(userId, 'restored');
      expect(auth.signInCount, 0);
    });

    /// A first launch signs in anonymously, without asking the user for anything.
    test('signs in anonymously when there is no session', () async {
      // Act
      final String userId = await service.ensureSignedIn();

      // Assert
      expect(userId, 'anonymous-1');
      expect(service.userId, 'anonymous-1');
      expect(auth.signInCount, 1);
    });

    /// The launch sign-in and an early data request may overlap, and must not create two accounts.
    test('signs in once when called again while signing in', () async {
      // Arrange
      auth.gate = Completer<void>();

      // Act
      final Future<String> first = service.ensureSignedIn();
      final Future<String> second = service.ensureSignedIn();
      auth.gate!.complete();

      // Assert
      expect(await first, 'anonymous-1');
      expect(await second, 'anonymous-1');
      expect(auth.signInCount, 1);
    });

    /// A disabled provider needs a console change, while a network failure can be retried, so they are told apart.
    test('reports why sign-in failed, and tries again later', () async {
      // Arrange
      auth.signInError = FirebaseAuthException(code: 'operation-not-allowed');

      // Act and assert
      expect(await failureOf(service.ensureSignedIn()), AuthFailure.disabled);

      // Arrange
      auth.signInError = FirebaseAuthException(code: 'network-request-failed');

      // Act and assert
      expect(await failureOf(service.ensureSignedIn()), AuthFailure.network);

      // Arrange
      auth.signInError = null;

      // Act and assert
      expect(await service.ensureSignedIn(), 'anonymous-3');
    });
  });
}
