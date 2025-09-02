import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../core/errors/exception.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/enums/roles_usuario.dart';
import '../../domain/exceptions/auth_exception.dart' as domain_exceptions;
import '../../domain/exceptions/user_exception.dart';
import '../../domain/failures/failures.dart';
import '../../domain/failures/result.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/firestore_datasource.dart';
import '../models/user_model.dart';

/// Implementación del repositorio de usuarios que utiliza Firebase
class UserRepositoryImpl implements IUserRepository {
  final FirebaseAuthDataSource _authDataSource;
  final FirestoreDataSource<UserModel> _firestoreDataSource;

  // Collection path para los usuarios en Firestore
  static const String _usersCollection = 'users';

  UserRepositoryImpl({
    required FirebaseAuthDataSource authDataSource,
    required FirestoreDataSource<UserModel> firestoreDataSource,
  })  : _authDataSource = authDataSource,
        _firestoreDataSource = firestoreDataSource;

  /// Maneja las excepciones de las fuentes de datos y las convierte a excepciones de dominio
  Future<T> _handleExceptions<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on domain_exceptions.AuthException catch (e) {
      // Reenviar excepciones de autenticación sin cambios
      throw e;
    } on DatabaseException catch (e) {
      throw UserException(
        'Error en la base de datos: ${e.message}',
        code: e.code,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw domain_exceptions.AuthException(
        'Error de autenticación: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw UserException('Error inesperado: $e');
    }
  }

  @override
  Future<domain.User?> obtenerUsuarioActual() async {
    return await _handleExceptions(() async {
      // Primero intentamos obtener el usuario autenticado
      final currentUser = _authDataSource.getCurrentUser();
      if (currentUser == null) return null;

      try {
        // Si el usuario está autenticado, obtenemos sus datos completos de Firestore
        final userData = await _firestoreDataSource.getById(currentUser.id);
        return userData?.toDomain();
      } catch (e) {
        // Si no existe en Firestore, devolvemos el usuario básico de Auth
        return currentUser;
      }
    });
  }

  @override
  Future<domain.User?> obtenerUsuarioPorId(String id) async {
    return await _handleExceptions(() async {
      final userData = await _firestoreDataSource.getById(id);
      return userData?.toDomain();
    });
  }

  @override
  Future<List<domain.User>> obtenerUsuariosPorRol(UserRole rol) async {
    return await _handleExceptions(() async {
      final usersData = await _firestoreDataSource.getWhere(
        field: 'rol',
        isEqualTo: rol.value,
      );
      return usersData.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Future<void> guardarUsuario(domain.User usuario) async {
    return await _handleExceptions(() async {
      final userModel = UserModel.fromDomain(usuario);
      await _firestoreDataSource.save(userModel);
    });
  }

  @override
  Future<void> actualizarPerfil({
    required String userId,
    String? nombre,
    String? avatarUrl,
    String? departamento,
    String? municipio,
    String? biografia,
  }) async {
    return await _handleExceptions(() async {
      // Obtener el usuario actual
      final userData = await _firestoreDataSource.getById(userId);
      if (userData == null) {
        throw UserException.noEncontrado(userId: userId);
      }

      // Actualizar solo los campos proporcionados
      final updatedModel = userData.copyWith(
        nombre: nombre,
        avatarUrl: avatarUrl,
        departamento: departamento,
        municipio: municipio,
        biografia: biografia,
      );

      await _firestoreDataSource.save(updatedModel);
    });
  }

  @override
  Future<void> actualizarRol({
    required String userId,
    required UserRole nuevoRol,
  }) async {
    return await _handleExceptions(() async {
      final userData = await _firestoreDataSource.getById(userId);
      if (userData == null) {
        throw UserException.noEncontrado(userId: userId);
      }

      final updatedModel = userData.copyWith(
        rol: nuevoRol.value,
      );

      await _firestoreDataSource.save(updatedModel);
    });
  }

  @override
  Future<void> desactivarCuenta(String userId) async {
    return await _handleExceptions(() async {
      final userData = await _firestoreDataSource.getById(userId);
      if (userData == null) {
        throw UserException.noEncontrado(userId: userId);
      }

      final updatedModel = userData.copyWith(
        activo: false,
      );

      await _firestoreDataSource.save(updatedModel);
    });
  }

  @override
  Future<void> reactivarCuenta(String userId) async {
    return await _handleExceptions(() async {
      final userData = await _firestoreDataSource.getById(userId);
      if (userData == null) {
        throw UserException.noEncontrado(userId: userId);
      }

      final updatedModel = userData.copyWith(
        activo: true,
      );

      await _firestoreDataSource.save(updatedModel);
    });
  }

  @override
  Future<void> actualizarEstadisticas({
    required String userId,
    int? relatosPublicados,
    int? saberesCompartidos,
    int? puntajeTotal,
  }) async {
    return await _handleExceptions(() async {
      final userData = await _firestoreDataSource.getById(userId);
      if (userData == null) {
        throw UserException.noEncontrado(userId: userId);
      }

      // Si se proporciona un delta, sumarlo al valor actual
      final updatedModel = userData.copyWith(
        relatosPublicados: relatosPublicados != null 
            ? userData.relatosPublicados + relatosPublicados 
            : null,
        saberesCompartidos: saberesCompartidos != null 
            ? userData.saberesCompartidos + saberesCompartidos 
            : null,
        puntajeTotal: puntajeTotal != null 
            ? userData.puntajeTotal + puntajeTotal 
            : null,
      );

      await _firestoreDataSource.save(updatedModel);
    });
  }

  @override
  Future<void> actualizarPreferenciasNotificaciones({
    required String userId,
    required bool notificacionesActivas,
  }) async {
    return await _handleExceptions(() async {
      final userData = await _firestoreDataSource.getById(userId);
      if (userData == null) {
        throw UserException.noEncontrado(userId: userId);
      }

      final updatedModel = userData.copyWith(
        notificacionesActivas: notificacionesActivas,
      );

      await _firestoreDataSource.save(updatedModel);
    });
  }

  @override
  Stream<domain.User?> observarUsuarioActual() {
    return _authDataSource.authStateChanges;
  }

  @override
  Stream<domain.User?> observarUsuarioPorId(String id) {
    return _firestoreDataSource.watchDocument(id).map((model) => model?.toDomain());
  }

  @override
  Future<List<domain.User>> buscarUsuarios(String texto) async {
    return await _handleExceptions(() async {
      // Implementación básica: buscar por nombre que contenga el texto
      // Una implementación más avanzada podría usar índices de búsqueda específicos
      final query = await _firestoreDataSource.query(
        filters: {
          'nombre_search': ['nombre', '>=', texto],
        },
        limit: 20,
      );
      
      // Filtrar en la aplicación para refinar resultados
      // (Firestore no tiene búsqueda de texto completa integrada)
      final filtered = query.where((model) => 
        model.nombre.toLowerCase().contains(texto.toLowerCase())
      ).toList();
      
      return filtered.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Future<Map<String, int>> obtenerEstadisticasUsuario(String userId) async {
    return await _handleExceptions(() async {
      final userData = await _firestoreDataSource.getById(userId);
      if (userData == null) {
        throw UserException.noEncontrado(userId: userId);
      }

      return {
        'relatosPublicados': userData.relatosPublicados,
        'saberesCompartidos': userData.saberesCompartidos,
        'puntajeTotal': userData.puntajeTotal,
      };
    });
  }

  // Métodos de autenticación

  @override
  Future<domain.User> iniciarSesionEmail({
    required String email,
    required String password,
  }) async {
    return await _handleExceptions(() async {
      final user = await _authDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Verificar si existe en Firestore, si no, crearlo
      await _asegurarPerfilCompleto(user);
      
      return user;
    });
  }

  @override
  Future<domain.User> iniciarSesionGoogle() async {
    return await _handleExceptions(() async {
      final user = await _authDataSource.signInWithGoogle();
      
      // Verificar si existe en Firestore, si no, crearlo
      await _asegurarPerfilCompleto(user);
      
      return user;
    });
  }

  @override
  Future<domain.User> iniciarSesionApple() async {
    // Firebase Auth Datasource no implementa Apple Sign In en este momento
    throw UnimplementedError('Inicio de sesión con Apple aún no implementado');
  }

  @override
  Future<domain.User> registrarEmail({
    required String email,
    required String password,
    required String nombre,
  }) async {
    return await _handleExceptions(() async {
      final user = await _authDataSource.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: nombre,
      );
      
      // Crear perfil completo en Firestore
      final userModel = UserModel.fromDomain(user);
      await _firestoreDataSource.save(userModel);
      
      return user;
    });
  }

  @override
  Future<void> cerrarSesion() async {
    return await _handleExceptions(() async {
      await _authDataSource.signOut();
    });
  }

  @override
  Future<void> eliminarCuenta(String userId) async {
    // Esta implementación solo marca como eliminada la cuenta en Firestore
    // Una implementación completa también eliminaría la cuenta de Firebase Auth
    return await _handleExceptions(() async {
      final userData = await _firestoreDataSource.getById(userId);
      if (userData == null) {
        throw UserException.noEncontrado(userId: userId);
      }

      // Marcar como eliminada pero no borrar (soft delete)
      final updatedModel = userData.copyWith(
        activo: false,
      );

      await _firestoreDataSource.save(updatedModel);
      
      // Nota: Para eliminar completamente de Firebase Auth se requiere
      // reautenticación por seguridad, lo que está fuera del alcance de esta implementación
    });
  }

  @override
  Future<void> enviarEmailVerificacion() {
    throw UnimplementedError('Envío de email de verificación no implementado');
  }

  @override
  Future<void> enviarResetPassword(String email) async {
    return await _handleExceptions(() async {
      await _authDataSource.resetPassword(email);
    });
  }

  @override
  Future<bool> verificarEmailExiste(String email) {
    throw UnimplementedError('Verificación de email existente no implementada');
  }

  @override
  Future<void> actualizarPassword({
    required String oldPassword,
    required String newPassword,
  }) {
    throw UnimplementedError('Actualización de contraseña no implementada');
  }

  @override
  Future<void> vincularGoogle() {
    throw UnimplementedError('Vinculación de cuenta Google no implementada');
  }

  @override
  Future<void> vincularApple() {
    throw UnimplementedError('Vinculación de cuenta Apple no implementada');
  }

  @override
  Future<void> desvincularProveedor(String providerId) {
    throw UnimplementedError('Desvinculación de proveedor no implementada');
  }

  // Métodos privados de ayuda
  
  /// Asegura que el usuario tenga un perfil completo en Firestore
  Future<void> _asegurarPerfilCompleto(domain.User user) async {
    try {
      final existingUser = await _firestoreDataSource.getById(user.id);
      if (existingUser == null) {
        // Si no existe en Firestore, crearlo
        final userModel = UserModel.fromDomain(user);
        await _firestoreDataSource.save(userModel);
      }
      // Si ya existe, no hacemos nada
    } catch (e) {
      // Si hay error al verificar, intentamos crear de todos modos
      final userModel = UserModel.fromDomain(user);
      await _firestoreDataSource.save(userModel);
    }
  }
}
