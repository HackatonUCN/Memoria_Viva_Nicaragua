import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:memoria_viva_nicaragua/data/datasources/impl/firebase_auth_datasource_impl.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart' as domain;
import 'package:memoria_viva_nicaragua/domain/exceptions/auth_exception.dart' as domain_exceptions;

class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}
class MockFirebaseUser extends Mock implements firebase_auth.User {}
class MockUserCredential extends Mock implements firebase_auth.UserCredential {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}

void main() {
  setUpAll(() {
    final fallback = firebase_auth.GoogleAuthProvider.credential(accessToken: 'acc', idToken: 'id');
    registerFallbackValue(fallback);
  });

  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late FirebaseAuthDataSourceImpl dataSource;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    dataSource = FirebaseAuthDataSourceImpl(auth: mockAuth, googleSignIn: mockGoogleSignIn);
  });

  group('FirebaseAuthDataSourceImpl', () {
    test('signInAnonymously - éxito', () async {
      final mockUser = MockFirebaseUser();
      final mockCred = MockUserCredential();
      when(() => mockCred.user).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('anon-1');
      // Proveer email válido para cumplir validaciones del dominio
      when(() => mockUser.email).thenReturn('anon@local');
      when(() => mockUser.displayName).thenReturn(null);
      when(() => mockUser.isAnonymous).thenReturn(true);

      when(() => mockAuth.signInAnonymously()).thenAnswer((_) async => mockCred);

      final user = await dataSource.signInAnonymously();
      expect(user.id, 'anon-1');
    });

    test('isAuthenticated e isAnonymous reflejan el estado', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(dataSource.isAuthenticated(), isFalse);
      expect(dataSource.isAnonymous(), isTrue);

      final mockUser = MockFirebaseUser();
      when(() => mockUser.isAnonymous).thenReturn(false);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      expect(dataSource.isAuthenticated(), isTrue);
      expect(dataSource.isAnonymous(), isFalse);
    });

    test('mapea error desconocido en signInWithEmailAndPassword a unknown-error', () async {
      when(() => mockAuth.signInWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(Exception('boom'));
      expect(
        () => dataSource.signInWithEmailAndPassword(email: 'a@b.com', password: 'x'),
        throwsA(isA<domain_exceptions.AuthException>().having((e) => e.code, 'code', 'unknown-error')),
      );
    });

    test('mapea network-request-failed a AuthException con code correspondiente', () {
      when(() => mockAuth.signInWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(firebase_auth.FirebaseAuthException(code: 'network-request-failed'));
      expect(
        () => dataSource.signInWithEmailAndPassword(email: 'x@y.com', password: 'z'),
        throwsA(isA<domain_exceptions.AuthException>().having((e) => e.code, 'code', 'network-request-failed')),
      );
    });
    test('signInWithEmailAndPassword - éxito', () async {
      final mockUser = MockFirebaseUser();
      when(() => mockUser.uid).thenReturn('uid-123');
      when(() => mockUser.email).thenReturn('john@example.com');
      when(() => mockUser.displayName).thenReturn('John Doe');
      when(() => mockUser.isAnonymous).thenReturn(false);

      final mockCred = MockUserCredential();
      when(() => mockCred.user).thenReturn(mockUser);

      when(() => mockAuth.signInWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => mockCred);

      final user = await dataSource.signInWithEmailAndPassword(email: 'john@example.com', password: 'secret');

      expect(user.id, 'uid-123');
      expect(user.email, 'john@example.com');
      expect(user.nombre, 'John Doe');
    });

    test('signInWithEmailAndPassword - mapea FirebaseAuthException a AuthException', () async {
      when(() => mockAuth.signInWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(firebase_auth.FirebaseAuthException(code: 'wrong-password', message: 'Wrong password'));

      expect(
        () => dataSource.signInWithEmailAndPassword(email: 'a@b.com', password: 'x'),
        throwsA(isA<domain_exceptions.AuthException>().having((e) => e.code, 'code', 'wrong-password')),
      );
    });

    test('registerWithEmailAndPassword - éxito actualiza displayName y devuelve usuario', () async {
      final mockUser = MockFirebaseUser();
      when(() => mockUser.uid).thenReturn('uid-123');
      when(() => mockUser.email).thenReturn('john@example.com');
      when(() => mockUser.displayName).thenReturn('John Doe');
      when(() => mockUser.isAnonymous).thenReturn(false);
      when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => mockUser.reload()).thenAnswer((_) async {});

      final mockCred = MockUserCredential();
      when(() => mockCred.user).thenReturn(mockUser);

      when(() => mockAuth.createUserWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => mockCred);
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final user = await dataSource.registerWithEmailAndPassword(
        email: 'john@example.com', password: 'secret', displayName: 'John Doe',
      );

      expect(user.id, 'uid-123');
      verify(() => mockUser.updateDisplayName('John Doe')).called(1);
      verify(() => mockUser.reload()).called(1);
    });

    test('signInWithGoogle - éxito en móvil usando GoogleSignIn', () async {
      final mockAccount = MockGoogleSignInAccount();
      final mockAuthTokens = MockGoogleSignInAuthentication();
      final mockUser = MockFirebaseUser();
      final mockCred = MockUserCredential();

      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authentication).thenAnswer((_) async => mockAuthTokens);
      when(() => mockAuthTokens.accessToken).thenReturn('access');
      when(() => mockAuthTokens.idToken).thenReturn('id');

      when(() => mockAuth.signInWithCredential(any())).thenAnswer((_) async => mockCred);
      when(() => mockCred.user).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('uid-123');
      when(() => mockUser.email).thenReturn('john@example.com');
      when(() => mockUser.displayName).thenReturn('John Doe');
      when(() => mockUser.isAnonymous).thenReturn(false);

      final user = await dataSource.signInWithGoogle();
      expect(user.id, 'uid-123');
    });

    test('signInWithGoogle - cancelado por el usuario', () async {
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);
      expect(
        () => dataSource.signInWithGoogle(),
        throwsA(isA<domain_exceptions.AuthException>().having((e) => e.code, 'code', 'google-sign-in-canceled')),
      );
    });

    test('signOut - cierra sesión en Google y Firebase', () async {
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await dataSource.signOut();
      verify(() => mockGoogleSignIn.signOut()).called(1);
      verify(() => mockAuth.signOut()).called(1);
    });

    test('getCurrentUser - null cuando no hay usuario', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      final user = dataSource.getCurrentUser();
      expect(user, isNull);
    });

    test('getCurrentUser - devuelve usuario mapeado', () {
      final mockUser = MockFirebaseUser();
      when(() => mockUser.uid).thenReturn('uid-123');
      when(() => mockUser.email).thenReturn('john@example.com');
      when(() => mockUser.displayName).thenReturn('John Doe');
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockUser.isAnonymous).thenReturn(false);
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final user = dataSource.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.email, 'john@example.com');
    });

    test('resetPassword - mapea errores de Firebase a AuthException', () async {
      when(() => mockAuth.sendPasswordResetEmail(email: any(named: 'email')))
          .thenThrow(firebase_auth.FirebaseAuthException(code: 'user-not-found', message: 'No user'));

      expect(
        () => dataSource.resetPassword('nouser@example.com'),
        throwsA(isA<domain_exceptions.AuthException>().having((e) => e.code, 'code', 'user-not-found')),
      );
    });

    test('getIdToken - éxito', () async {
      final mockUser = MockFirebaseUser();
      when(() => mockUser.getIdToken()).thenAnswer((_) async => 'token-123');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final token = await dataSource.getIdToken();
      expect(token, 'token-123');
    });

    test('getIdToken - lanza AuthException ante error', () async {
      final mockUser = MockFirebaseUser();
      when(() => mockUser.getIdToken()).thenThrow(Exception('boom'));
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      expect(
        () => dataSource.getIdToken(),
        throwsA(isA<domain_exceptions.AuthException>().having((e) => e.code, 'code', 'get-token-failed')),
      );
    });
  });
}


