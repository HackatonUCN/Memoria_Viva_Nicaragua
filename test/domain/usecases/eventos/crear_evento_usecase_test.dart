import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/eventos/crear_evento_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/evento_cultural_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/categoria_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/validators/contenido_validator.dart';
import 'package:memoria_viva_nicaragua/domain/entities/evento_cultural.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';
import 'package:memoria_viva_nicaragua/domain/entities/categoria.dart';
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';
import 'package:memoria_viva_nicaragua/domain/enums/tipos_evento.dart';
import 'package:memoria_viva_nicaragua/domain/enums/tipos_contenido.dart';
import 'package:memoria_viva_nicaragua/domain/value_objects/ubicacion.dart';

class _EventoRepoStub implements IEventoCulturalRepository {
  EventoCultural? ultimo;
  @override
  Future<void> guardarEvento(EventoCultural evento) async { ultimo = evento; }
  @override
  Future<List<EventoCultural>> buscarEventos(String texto) async => [];
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CategoriaRepoStub implements ICategoriaRepository {
  final bool existe;
  _CategoriaRepoStub(this.existe);
  @override
  Future<Categoria?> obtenerCategoriaPorId(String id) async => existe
      ? Categoria.crear(nombre: 'Cat', descripcion: 'd', tipo: TipoContenido.evento, icono: 'i', color: '#FFFFFF', orden: 0)
      : null;
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserRepoStub implements IUserRepository {
  final User? user;
  _UserRepoStub(this.user);
  @override
  Future<User?> obtenerUsuarioPorId(String id) async => user;
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ContenidoValidatorFake implements ContenidoValidator {
  @override
  void validarEventoCultural(EventoCultural evento) { /* válido */ }
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CrearEventoUseCase', () {
    test('admin crea evento exitosamente', () async {
      final repo = _EventoRepoStub();
      final catRepo = _CategoriaRepoStub(true);
      final userRepo = _UserRepoStub(User.crear(id: 'a', nombre: 'Admin', email: 'a@a.com', rol: UserRole.admin));
      final validator = _ContenidoValidatorFake();
      final usecase = CrearEventoUseCase(repo, catRepo, userRepo, validator);

      final ubicacion = Ubicacion(latitud: 12.136389, longitud: -86.251389, departamento: 'Managua', municipio: 'Managua');
      final now = DateTime.now().toUtc().add(const Duration(days: 2));
      final result = await usecase.execute(
        adminId: 'a', nombre: 'Feria', descripcion: 'Desc', tipo: TipoEvento.feria,
        categoriaId: 'c1', fechaInicio: now, fechaFin: now.add(const Duration(days: 1)),
        organizador: 'Org', departamento: ubicacion.departamento, municipio: ubicacion.municipio,
        latitud: ubicacion.latitud, longitud: ubicacion.longitud,
      );
      expect(result.isSuccess, isTrue);
      expect(repo.ultimo, isNotNull);
    });

    test('falla si no es admin', () async {
      final repo = _EventoRepoStub();
      final catRepo = _CategoriaRepoStub(true);
      final userRepo = _UserRepoStub(User.crear(id: 'n', nombre: 'Normal', email: 'n@n.com', rol: UserRole.normal));
      final validator = _ContenidoValidatorFake();
      final usecase = CrearEventoUseCase(repo, catRepo, userRepo, validator);

      final ubicacion = Ubicacion(latitud: 12.136389, longitud: -86.251389, departamento: 'Managua', municipio: 'Managua');
      final now = DateTime.now().toUtc().add(const Duration(days: 2));
      final result = await usecase.execute(
        adminId: 'n', nombre: 'Feria', descripcion: 'Desc', tipo: TipoEvento.feria,
        categoriaId: 'c1', fechaInicio: now, fechaFin: now.add(const Duration(days: 1)),
        organizador: 'Org', departamento: ubicacion.departamento, municipio: ubicacion.municipio,
        latitud: ubicacion.latitud, longitud: ubicacion.longitud,
      );
      expect(result.isFailure, isTrue);
    });
  });
}
