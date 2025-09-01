import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/eventos/crear_sugerencia_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/evento_cultural_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/categoria_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/validators/contenido_validator.dart';
import 'package:memoria_viva_nicaragua/domain/entities/evento_cultural.dart';
import 'package:memoria_viva_nicaragua/domain/entities/categoria.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';
import 'package:memoria_viva_nicaragua/domain/enums/tipos_contenido.dart';
import 'package:memoria_viva_nicaragua/domain/enums/tipos_evento.dart';

class _EventoRepoStub implements IEventoCulturalRepository {
  SugerenciaEvento? guardada;
  @override
  Future<void> guardarSugerencia(SugerenciaEvento sugerencia) async { guardada = sugerencia; }
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CategoriaRepoStub implements ICategoriaRepository {
  @override
  Future<Categoria?> obtenerCategoriaPorId(String id) async => Categoria.crear(
    nombre: 'Cat', descripcion: 'd', tipo: TipoContenido.evento, icono: 'i', color: '#FFFFFF', orden: 0,
  );
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
  void validarEventoCultural(EventoCultural evento) { /* no usado aquí */ }
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CrearSugerenciaUseCase', () {
    test('crea sugerencia exitosamente', () async {
      final repo = _EventoRepoStub();
      final catRepo = _CategoriaRepoStub();
      final userRepo = _UserRepoStub(User.crear(id: 'u1', nombre: 'U', email: 'u@u.com', rol: UserRole.normal));
      final validator = _ContenidoValidatorFake();
      final usecase = CrearSugerenciaUseCase(repo, catRepo, userRepo, validator);

      final result = await usecase.execute(
        usuarioId: 'u1', nombre: 'Feria', descripcion: 'Desc', categoriaId: 'c1', tipo: TipoEvento.feria,
        departamento: 'Managua', municipio: 'Managua', fechaInicio: DateTime.now().toUtc().add(const Duration(days: 5)),
        fechaFin: DateTime.now().toUtc().add(const Duration(days: 6)), organizador: 'Org', imagenesUrls: const [],
        latitud: 12.136389, longitud: -86.251389,
      );
      expect(result.isSuccess, isTrue);
      expect(repo.guardada, isNotNull);
    });

    test('falla por usuario invitado', () async {
      final repo = _EventoRepoStub();
      final catRepo = _CategoriaRepoStub();
      final userRepo = _UserRepoStub(User.crear(id: 'u1', nombre: 'U', email: 'u@u.com', rol: UserRole.invitado));
      final validator = _ContenidoValidatorFake();
      final usecase = CrearSugerenciaUseCase(repo, catRepo, userRepo, validator);

      final result = await usecase.execute(
        usuarioId: 'u1', nombre: 'Feria', descripcion: 'Desc', categoriaId: 'c1', tipo: TipoEvento.feria,
        departamento: 'Managua', municipio: 'Managua', fechaInicio: DateTime.now().toUtc().add(const Duration(days: 5)),
        fechaFin: DateTime.now().toUtc().add(const Duration(days: 6)), organizador: 'Org', imagenesUrls: const [],
        latitud: 12.136389, longitud: -86.251389,
      );
      expect(result.isFailure, isTrue);
    });
  });
}
