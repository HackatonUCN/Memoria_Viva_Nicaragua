import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import '../../data/infrastructure/services/auth_service.dart';
import '../../data/infrastructure/services/firebase_services_manager.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart' as domain;
import 'package:memoria_viva_nicaragua/domain/factories/usecases.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  authenticating,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final _useCases = UseCases.resolve().auth;
  AuthStatus _status = AuthStatus.initial;
  domain.User? _user;
  String? _errorMessage;
  bool _isAnonymous = false;

  // Getters
  AuthStatus get status => _status;
  domain.User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAnonymous => _isAnonymous;

  AuthProvider() {
    // Escuchar cambios desde la capa de dominio (UserRepository -> FirebaseAuth)
    _useCases.getCurrentUser.observe().listen((domain.User? user) {
      _user = user;
      _isAnonymous = user?.esInvitado ?? false;

      final manager = FirebaseServicesManager.instance;
      if (user == null) {
        _status = AuthStatus.unauthenticated;
        manager.logEvent('auth_state_changed', parameters: {'state': 'unauthenticated'});
      } else {
        _status = AuthStatus.authenticated;
        final role = _isAnonymous ? 'guest' : 'registered';
        manager.setUserContext(
          userId: user.id,
          userRole: role,
          properties: {
            'isAnonymous': _isAnonymous.toString(),
            'hasEmail': (user.email.isNotEmpty).toString(),
          },
        );
        // Guardar token del dispositivo para envíos futuros
        manager.saveDeviceToken(userId: user.id);
        manager.logEvent('auth_state_changed', parameters: {'state': 'authenticated', 'role': role});
      }

      notifyListeners();
    });
  }

  // Consentimiento de privacidad para Analytics/Performance (y opcionalmente Crashlytics)
  Future<void> updatePrivacyConsent(bool granted) async {
    try {
      await FirebaseServicesManager.instance.setPrivacyConsent(granted: granted);
      notifyListeners();
    } catch (e) {
      // No propagamos error a UI; dejamos log
      FirebaseServicesManager.instance.logError('privacy_consent_update_failed', error: e);
    }
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
      final result = await _useCases.loginWithEmail.execute(email: email, password: password);
      if (result.isFailure) {
        _status = AuthStatus.error;
        _errorMessage = result.errorOrNull?.message;
        notifyListeners();
        return;
      }
      // El listener actualizará el estado
      FirebaseServicesManager.instance.logEvent('auth_login', parameters: {'method': 'password'});
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
      final result = await _useCases.registerUser.execute(
        email: email,
        password: password,
        nombre: displayName,
      );
      if (result.isFailure) {
        _status = AuthStatus.error;
        _errorMessage = result.errorOrNull?.message;
        notifyListeners();
        return;
      }
      FirebaseServicesManager.instance.logEvent('auth_register', parameters: {'method': 'password'});
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
      final result = await _useCases.loginWithGoogle.execute();
      if (result.isFailure) {
        _status = AuthStatus.error;
        _errorMessage = result.errorOrNull?.message;
        notifyListeners();
        return;
      }
      FirebaseServicesManager.instance.logEvent('auth_login', parameters: {'method': 'google'});
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
      // Notificar éxito inmediato para que la UI pueda navegar sin esperar al stream
      _status = AuthStatus.authenticated;
      notifyListeners();
      FirebaseServicesManager.instance.logEvent('auth_login', parameters: {'method': 'anonymous'});
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      final result = await _useCases.logout.execute();
      if (result.isFailure) {
        _status = AuthStatus.error;
        _errorMessage = result.errorOrNull?.message;
        notifyListeners();
        return;
      }
      FirebaseServicesManager.instance.logEvent('auth_logout');
      // No necesitamos actualizar _status o _user aquí porque el listener lo hará
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
    }
  }

  // Manejar errores de autenticación
  String _handleAuthError(dynamic error) {
    if (error is fa.FirebaseAuthException) {
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
