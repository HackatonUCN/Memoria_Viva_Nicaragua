import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart' as domain;
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';
import 'package:memoria_viva_nicaragua/domain/factories/auth_usecase_factory.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/auth/login_with_email_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/auth/register_user_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/auth/logout_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/services/i_analytics_service.dart';

import '../support/fakes.dart';

class FakeAnalytics implements IAnalyticsService {
  @override
  Future<void> activarSeguimiento() async {}
  @override
  Future<void> desactivarSeguimiento() async {}
  @override
  Future<void> establecerPropiedadesUsuario(Map<String, dynamic> propiedades) async {}
  @override
  Future<Map<String, dynamic>> obtenerEstadisticasContenido({required String contenidoId, required String tipoContenido}) async => {};
  @override
  Future<Map<String, dynamic>> obtenerEstadisticasUsuario(String usuarioId) async => {};
  @override
  Future<Map<String, dynamic>> obtenerMetricasAplicacion({DateTime? fechaInicio, DateTime? fechaFin}) async => {};
  @override
  Future<void> registrarCierreSesion({int duracionSesionSegundos = 0}) async {}
  @override
  Future<void> registrarCreacionContenido({required String tipoContenido, required String contenidoId, Map<String, dynamic>? propiedades}) async {}
  @override
  Future<void> registrarError({required String mensaje, required String codigo, String? ubicacion, Map<String, dynamic>? contexto}) async {}
  @override
  Future<void> registrarEvento({required String nombre, Map<String, dynamic>? propiedades}) async {}
  @override
  Future<void> registrarInteraccion({required String contenidoId, required String tipoContenido, required String tipoInteraccion, Map<String, dynamic>? propiedades}) async {}
  @override
  Future<void> registrarInicioSesion({required String metodo, bool esNuevoUsuario = false}) async {}
  @override
  Future<void> registrarNavegacion({required String pantalla, String? pantallaAnterior, Map<String, dynamic>? propiedades}) async {}
  @override
  Future<void> registrarRendimiento({required String operacion, required int duracionMs, Map<String, dynamic>? metricas}) async {}
  @override
  Future<void> registrarUsoCaracteristica({required String caracteristica, Map<String, dynamic>? propiedades}) async {}
  @override
  Future<void> registrarVisualizacion({required String contenidoId, required String tipoContenido, Map<String, dynamic>? propiedades}) async {}
  @override
  Future<void> registrarBusqueda({required String consulta, required String tipoContenido, required int resultados, Map<String, dynamic>? filtros}) async {}
  @override
  Future<void> inicializar({usuario}) async {}
  @override
  Future<List<Map<String, dynamic>>> obtenerTendencias({String? tipoContenido, int limite = 10}) async => <Map<String, dynamic>>[];
  @override
  Future<void> registrarParticipacionEvento({required String eventoId, required String tipoParticipacion}) async {}
}

void main() {
  group('Integración - Flujo de Autenticación', () {
    late FakeAuthDataSource authDs;
    late IUserRepository userRepo; // Se podría implementar un userRepo en memoria si fuera necesario

    setUp(() {
      authDs = FakeAuthDataSource();
      // Para esta prueba, usaremos directamente los casos de uso que dependen de IUserRepository.
      // Podríamos proveer un IUserRepository fake que utilice authDs para cubrir la integración completa.
    });

    test('Registro → Obtener usuario actual → Logout', () async {
      // Arrange: Repositorio fake mínimo basado en datasource
      final repo = _UserRepositoryFake(authDs);
      final factory = AuthUseCaseFactory(
        userRepository: repo,
        analyticsService: FakeAnalytics(),
      );

      // Act: registrar
      final register = factory.registerUser;
      final regRes = await register.execute(email: 'test@mv.com', password: '123456', nombre: 'Test');
      expect(regRes.isSuccess, true);

      // Assert: obtener usuario actual
      final current = factory.getCurrentUser;
      final currRes = await current.execute();
      expect(currRes.isSuccess, true);
      expect(currRes.valueOrNull?.email, 'test@mv.com');

      // Act: logout
      final logout = factory.logout;
      final outRes = await logout.execute();
      expect(outRes.isSuccess, true);

      // Assert: usuario actual es null
      final currRes2 = await current.execute();
      expect(currRes2.valueOrNull, isNull);
    });

    test('Login falla con credenciales inválidas', () async {
      final repo = _UserRepositoryFake(authDs);
      final factory = AuthUseCaseFactory(userRepository: repo, analyticsService: FakeAnalytics());
      final login = factory.loginWithEmail;
      final res = await login.execute(email: 'no@existe.com', password: 'x');
      expect(res.isSuccess, false);
    });
  });
}

/// UserRepository fake básico para integrar con FakeAuthDataSource
class _UserRepositoryFake implements IUserRepository {
  final FakeAuthDataSource _auth;
  _UserRepositoryFake(this._auth);

  @override
  Future<void> actualizarEstadisticas({required String userId, int? relatosPublicados, int? saberesCompartidos, int? puntajeTotal}) async {}

  @override
  Future<void> actualizarPerfil({required String userId, String? nombre, String? avatarUrl, String? departamento, String? municipio, String? biografia}) async {}

  @override
  Future<void> actualizarRol({required String userId, required UserRole nuevoRol}) async {}

  @override
  Future<void> agregarCategoriaFavorita(String userId, String categoriaId) async {}
  @override
  Future<void> agregarEventoFavorito(String userId, String eventoId) async {}
  @override
  Future<void> agregarRelatoFavorito(String userId, String relatoId) async {}

  @override
  Future<void> cerrarSesion() => _auth.signOut();

  @override
  Future<void> eliminarCategoriaFavorita(String userId, String categoriaId) async {}
  @override
  Future<void> eliminarEventoFavorito(String userId, String eventoId) async {}
  @override
  Future<void> eliminarRelatoFavorito(String userId, String relatoId) async {}

  @override
  Future<void> enviarEmailVerificacion() async {}

  @override
  Stream<domain.User?> observarUsuarioActual() => _auth.authStateChanges;
  @override
  Stream<domain.User?> observarUsuarioPorId(String id) => const Stream.empty();

  @override
  Future<domain.User?> obtenerUsuarioActual() async => _auth.getCurrentUser();
  @override
  Future<domain.User?> obtenerUsuarioPorId(String id) async => _auth.getCurrentUser();
  @override
  Future<List<domain.User>> obtenerUsuariosPorRol(role) async => [];

  @override
  Future<domain.User> iniciarSesionApple() async => throw UnimplementedError();
  @override
  Future<domain.User> iniciarSesionEmail({required String email, required String password}) => _auth.signInWithEmailAndPassword(email: email, password: password);
  @override
  Future<domain.User> iniciarSesionGoogle() => _auth.signInWithGoogle();

  @override
  Future<void> reactivarCuenta(String userId) async {}
  @override
  Future<void> desactivarCuenta(String userId) async {}

  @override
  Future<void> guardarUsuario(domain.User usuario) async {}

  @override
  Future<void> enviarResetPassword(String email) async {}

  @override
  Future<domain.User> registrarEmail({required String email, required String password, required String nombre}) => _auth.registerWithEmailAndPassword(email: email, password: password, displayName: nombre);

  @override
  Future<bool> verificarEmailExiste(String email) async => false;

  @override
  Future<void> actualizarPassword({required String oldPassword, required String newPassword}) async {}
  @override
  Future<void> vincularApple() async {}
  @override
  Future<void> vincularGoogle() async {}
  @override
  Future<void> desvincularProveedor(String providerId) async {}
  @override
  Future<List<domain.User>> buscarUsuarios(String texto) async => [];
  @override
  Future<Map<String, int>> obtenerEstadisticasUsuario(String userId) async => {};
  @override
  Future<void> actualizarPreferenciasNotificaciones({required String userId, required bool notificacionesActivas}) async {}
  @override
  Future<void> eliminarCuenta(String userId) async {}
}


