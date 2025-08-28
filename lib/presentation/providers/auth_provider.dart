import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/infrastructure/services/auth_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  authenticating,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _isAnonymous = false;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAnonymous => _isAnonymous;

  AuthProvider() {
    // Inicializar escuchando cambios en el estado de autenticación
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      _isAnonymous = user?.isAnonymous ?? false;
      
      if (user == null) {
        _status = AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.authenticated;
      }
      
      notifyListeners();
    });
  }

  // Iniciar sesión con correo y contraseña
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();
      
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // No necesitamos actualizar _status o _user aquí porque el listener lo hará
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
    }
  }

  // Registrarse con correo y contraseña
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();
      
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      // No necesitamos actualizar _status o _user aquí porque el listener lo hará
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
    }
  }

  // Iniciar sesión con Google
  Future<void> signInWithGoogle() async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();
      
      await _authService.signInWithGoogle();
      
      // No necesitamos actualizar _status o _user aquí porque el listener lo hará
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
    }
  }

  // Restablecer contraseña
  Future<void> resetPassword(String email) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();
      
      await _authService.resetPassword(email);
      
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
    }
  }

  // Iniciar sesión como invitado
  Future<void> signInAnonymously() async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();
      
      await _authService.signInAnonymously();
      
      // No necesitamos actualizar _status o _user aquí porque el listener lo hará
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      
      // No necesitamos actualizar _status o _user aquí porque el listener lo hará
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
    }
  }

  // Manejar errores de autenticación
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No existe una cuenta con este correo electrónico.';
        case 'wrong-password':
          return 'Contraseña incorrecta.';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con este correo electrónico.';
        case 'weak-password':
          return 'La contraseña es demasiado débil.';
        case 'invalid-email':
          return 'El formato del correo electrónico no es válido.';
        case 'operation-not-allowed':
          return 'Esta operación no está permitida.';
        case 'ERROR_ABORTED_BY_USER':
          return 'Inicio de sesión cancelado por el usuario.';
        default:
          return 'Error de autenticación: ${error.message}';
      }
    }
    return 'Error desconocido: $error';
  }
}
