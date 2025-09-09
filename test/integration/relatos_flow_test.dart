import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart' as domain show User;
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';

import 'package:memoria_viva_nicaragua/domain/factories/relato_usecase_factory.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/relato_repository.dart';
import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';
import 'package:memoria_viva_nicaragua/domain/enums/estado_moderacion.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/categoria_repository.dart';
import 'package:memoria_viva_nicaragua/domain/entities/categoria.dart';
import 'package:memoria_viva_nicaragua/domain/enums/tipos_contenido.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/validators/contenido_validator.dart';
import 'package:memoria_viva_nicaragua/domain/value_objects/ubicacion.dart';
import 'package:memoria_viva_nicaragua/domain/failures/result.dart';

import '../support/fakes.dart';

void main() {
  group('Integración - Flujos de Relatos', () {
    late FakeAuthDataSource authDs;
    late _RelatoRepositoryFake relatoRepo;
    late _CategoriaRepositoryFake categoriaRepo;
    late _UserRepositoryFake userRepo;

    setUp(() {
      authDs = FakeAuthDataSource();
      userRepo = _UserRepositoryFake(authDs);
      categoriaRepo = _CategoriaRepositoryFake();
      relatoRepo = _RelatoRepositoryFake();
    });

    test('Crear relato exitoso', () async {
      // Registrar usuario
      await authDs.registerWithEmailAndPassword(email: 'a@a.com', password: '123456', displayName: 'Autor');
      final autor = authDs.getCurrentUser()!;
      categoriaRepo.seed('c1', 'Cultura');

      final factory = RelatoUseCaseFactory(
        relatoRepository: relatoRepo,
        categoriaRepository: categoriaRepo,
        userRepository: userRepo,
        validator: ContenidoValidator(),
      );

      final crear = factory.crear;
      final res = await crear.execute(
        titulo: 'Relato de prueba',
        contenido: 'Contenido muy interesante de prueba.' * 2,
        autorId: autor.id,
        categoriaId: 'c1',
        departamento: 'Managua',
        municipio: 'Managua',
        latitud: 12.1,
        longitud: -86.2,
        imagenesUrls: const [],
        etiquetas: const ['prueba'],
      );

      expect(res.isSuccess, true);
    });

    test('Crear relato falla por categoría inexistente', () async {
      await authDs.registerWithEmailAndPassword(email: 'b@b.com', password: '123456', displayName: 'Autor');
      final autor = authDs.getCurrentUser()!;

      final factory = RelatoUseCaseFactory(
        relatoRepository: relatoRepo,
        categoriaRepository: categoriaRepo,
        userRepository: userRepo,
        validator: ContenidoValidator(),
      );

      final crear = factory.crear;
      final res = await crear.execute(
        titulo: 'Relato',
        contenido: 'Contenido extenso válido.' * 2,
        autorId: autor.id,
        categoriaId: 'no-existe',
      );

      expect(res.isSuccess, false);
    });
  });
}

/// Fakes mínimos in-memory
class _RelatoRepositoryFake implements IRelatoRepository {
  @override
  Future<void> actualizarRelato(Relato relato) async {}

  @override
  Future<bool> toggleLike({required String id, required String userId}) async => true;

  @override
  Future<void> eliminarRelato(String id) async {}

  @override
  Future<List<Relato>> obtenerRelatos() async => <Relato>[];

  @override
  Future<Relato?> obtenerRelatoPorId(String id) async => null;

  @override
  Future<List<Relato>> obtenerRelatosCercanos({required double latitud, required double longitud, required double radioKm}) async => <Relato>[];

  @override
  Future<List<Relato>> obtenerRelatosPorAutor(String autorId) async => <Relato>[];

  @override
  Future<List<Relato>> obtenerRelatosPorCategoria(String categoriaId) async => <Relato>[];

  @override
  Future<List<Relato>> obtenerRelatosPorUbicacion({String? departamento, String? municipio}) async => <Relato>[];

  @override
  Future<void> registrarCompartido(String id) async {}

  @override
  Future<bool> reportarRelato(String id, String razon, {required String userId}) async => true;

  @override
  Future<void> restaurarRelato(String id) async {}

  @override
  Stream<List<Relato>> observarRelatos() => const Stream.empty();

  @override
  Stream<Relato?> observarRelatoPorId(String id) => const Stream.empty();

  @override
  Stream<List<Relato>> observarRelatosPorCategoria(String categoriaId) => const Stream.empty();

  @override
  Future<void> guardarRelato(Relato relato) async {}

  @override
  Future<List<Relato>> buscarRelatos(String texto) async => <Relato>[];

  @override
  Future<List<Relato>> buscarRelatosSimilares({required String titulo, required String autorId}) async => <Relato>[];

  @override
  Future<void> moderarRelato(String id, EstadoModeracion estado) async {}
}

class _CategoriaRepositoryFake implements ICategoriaRepository {
  final Map<String, Categoria> _data = {};
  void seed(String id, String nombre) => _data[id] = Categoria(
        id: id,
        nombre: nombre,
        descripcion: 'desc',
        tipo: TipoContenido.relato,
        icono: 'icon',
        color: '#FFFFFF',
        orden: 0,
        fechaCreacion: DateTime.now().toUtc(),
        fechaActualizacion: DateTime.now().toUtc(),
      );
  @override
  Future<void> actualizarCategoria(Categoria categoria) async {}
  @override
  Future<void> eliminarCategoria(String id) async {}
  @override
  Future<Categoria?> obtenerCategoriaPorId(String id) async => _data[id];
  @override
  Future<List<Categoria>> obtenerCategorias() async => _data.values.toList();
  @override
  Future<List<Categoria>> obtenerCategoriasPorTipo(TipoContenido tipo) async =>
      _data.values.where((c) => c.tipo == tipo).toList();
  @override
  Future<void> guardarCategoria(Categoria categoria) async {
    _data[categoria.id] = categoria;
  }
  @override
  Stream<List<Categoria>> observarCategorias() => const Stream.empty();
  @override
  Stream<Categoria?> observarCategoriaPorId(String id) => const Stream.empty();
  @override
  Future<List<Categoria>> obtenerSubcategorias(String categoriaPadreId) async => <Categoria>[];
}

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
  Future<void> cerrarSesion() => _auth.signOut();
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
  Future<List<domain.User>> obtenerUsuariosPorRol(UserRole rol) async => <domain.User>[];
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
  Future<List<domain.User>> buscarUsuarios(String texto) async => <domain.User>[];
  @override
  Future<Map<String, int>> obtenerEstadisticasUsuario(String userId) async => <String, int>{};
  @override
  Future<void> actualizarPreferenciasNotificaciones({required String userId, required bool notificacionesActivas}) async {}
  @override
  Future<void> eliminarCuenta(String userId) async {}
}

class _Categoria {
  final String id;
  final String nombre;
  _Categoria(this.id, this.nombre);
}

class _CategoriaModel {
  final String id;
  final String nombre;
  _CategoriaModel(this.id, this.nombre);
}


