import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../domain/entities/user.dart' as domain;
import '../../../domain/enums/roles_usuario.dart';
import '../../../domain/exceptions/auth_exception.dart';
import '../firebase_auth_datasource.dart';

/// Implementación de la fuente de datos de autenticación con Firebase
class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final firebase_auth.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthDataSourceImpl({
    firebase_auth.FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']);

  @override
  domain.User? getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    return _mapFirebaseUserToDomainUser(user);
  }

  @override
  Stream<domain.User?> get authStateChanges => 
      _auth.authStateChanges().map((firebase_auth.User? user) {
        return user != null ? _mapFirebaseUserToDomainUser(user) : null;
      });

  @override
  Future<domain.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw AuthException('No se encontró un usuario con estas credenciales', 
          code: 'user-not-found',
        );
      }
      
      return _mapFirebaseUserToDomainUser(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthExceptionToAuthException(e);
    } catch (e) {
      throw AuthException(e.toString(),
        code: 'unknown-error',
      );
    }
  }

  @override
  Future<domain.User> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw AuthException('El registro falló por motivos desconocidos',
          code: 'registration-failed',
        );
      }
      
      // Actualizar el nombre de usuario
      await userCredential.user!.updateDisplayName(displayName);
      // Recargar los datos del usuario para obtener el displayName actualizado
      await userCredential.user!.reload();
      final updatedUser = _auth.currentUser;
      
      return _mapFirebaseUserToDomainUser(updatedUser!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthExceptionToAuthException(e);
    } catch (e) {
      throw AuthException(e.toString(),
        code: 'unknown-error',
      );
    }
  }

  @override
  Future<domain.User> signInWithGoogle() async {
    try {
      firebase_auth.UserCredential userCredential;
      
      // Proceso de autenticación para Web
      if (kIsWeb) {
        final googleProvider = firebase_auth.GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } 
      // Proceso de autenticación para dispositivos móviles
      else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
                  throw AuthException('Inicio de sesión con Google cancelado por el usuario',
          code: 'google-sign-in-canceled',
        );
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }
      
      if (userCredential.user == null) {
        throw AuthException('El inicio de sesión con Google falló',
          code: 'google-sign-in-failed',
        );
      }
      
      return _mapFirebaseUserToDomainUser(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthExceptionToAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      
      throw AuthException(e.toString(),
        code: 'unknown-error',
      );
    }
  }

  @override
  Future<domain.User> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      
      if (userCredential.user == null) {
        throw AuthException('El inicio de sesión anónimo falló',
          code: 'anonymous-sign-in-failed',
        );
      }
      
      return _mapFirebaseUserToDomainUser(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthExceptionToAuthException(e);
    } catch (e) {
      throw AuthException(e.toString(),
        code: 'unknown-error',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut().catchError((_) {});
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Error al cerrar sesión: ${e.toString()}',
        code: 'sign-out-failed',
      );
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthExceptionToAuthException(e);
    } catch (e) {
      throw AuthException( 'Error al restablecer la contraseña: ${e.toString()}',
        code: 'reset-password-failed',

      );
    }
  }

  @override
  bool isAnonymous() {
    return _auth.currentUser?.isAnonymous ?? true;
  }

  @override
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  @override
  Future<String?> getIdToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      throw AuthException('Error al obtener el token: ${e.toString()}',
        code: 'get-token-failed',
      );
    }
  }

  // Métodos privados de mapeo
  
  /// Mapea un usuario de Firebase a la entidad de dominio User
  domain.User _mapFirebaseUserToDomainUser(firebase_auth.User firebaseUser) {
    // Asumimos un rol por defecto basado en si es anónimo
    final role = firebaseUser.isAnonymous 
        ? UserRole.invitado 
        : UserRole.normal;
    
    return domain.User.crear(
      id: firebaseUser.uid,
      nombre: firebaseUser.displayName ?? 'Usuario',
      email: firebaseUser.email ?? '',
      rol: role,
      avatarUrl: firebaseUser.photoURL,
    );
  }

  /// Mapea una excepción de Firebase Auth a la excepción de dominio AuthException
  AuthException _mapFirebaseAuthExceptionToAuthException(
      firebase_auth.FirebaseAuthException exception) {
    // Códigos de error comunes de Firebase Auth
    switch (exception.code) {
      case 'user-not-found':
        return AuthException('No existe una cuenta asociada a este correo',
          code: exception.code,
        );
      case 'wrong-password':
        return AuthException('Contraseña incorrecta',
          code: exception.code,
        );
      case 'email-already-in-use':
        return AuthException('Este correo ya está registrado',
          code: exception.code,

        );
      case 'weak-password':
        return AuthException('La contraseña es demasiado débil',
          code: exception.code,

        );
      case 'invalid-email':
        return AuthException('El formato del correo electrónico no es válido',
          code: exception.code,

        );
      case 'account-exists-with-different-credential':
        return AuthException('Ya existe una cuenta con este correo usando otro método',
          code: exception.code,

        );
      case 'operation-not-allowed':
        return AuthException('Esta operación no está permitida',
          code: exception.code,

        );
      case 'user-disabled':
        return AuthException('Esta cuenta ha sido deshabilitada',
          code: exception.code,

        );
      case 'network-request-failed':
        return AuthException('Error de conexión, verifica tu internet',
          code: exception.code,

        );
      case 'too-many-requests':
        return AuthException('Demasiados intentos fallidos. Intenta más tarde',
          code: exception.code,

        );
      default:
        return AuthException(exception.message ?? 'Error de autenticación desconocido',
          code: exception.code,

        );
    }
  }
}
