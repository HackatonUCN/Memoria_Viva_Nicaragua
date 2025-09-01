import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/relatos/crear_relato_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/relato_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/categoria_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/validators/contenido_validator.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';
import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';
import 'package:memoria_viva_nicaragua/domain/entities/categoria.dart';
import 'package:memoria_viva_nicaragua/domain/enums/tipos_contenido.dart';

class _RelatoRepoStub implements IRelatoRepository {
  Relato? ultimo;
  @override
  Future<void> guardarRelato(Relato relato) async { ultimo = relato; }
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CategoriaRepoStub implements ICategoriaRepository {
  final bool existe;
  _CategoriaRepoStub(this.existe);
  @override
  Future<Categoria?> obtenerCategoriaPorId(String id) async => existe
      ? Categoria.crear(nombre: 'Cat', descripcion: 'd', tipo: TipoContenido.relato, icono: 'i', color: '#FFFFFF', orden: 0)
      : null;
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserRepoStub implements IUserRepository {
  final User? user;
  _UserRepoStub(this.user);
  @override
  Future<User?> obtenerUsuarioPorId(String id) async => user;
  @override
  Future<void> actualizarEstadisticas({required String userId, int? relatosPublicados, int? saberesCompartidos, int? puntajeTotal}) async {}
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ContenidoValidatorFake implements ContenidoValidator {
  @override
  void validarRelato(Relato relato) { /* válido */ }
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CrearRelatoUseCase', () {
    test('crea relato exitosamente', () async {
      final repo = _RelatoRepoStub();
      final catRepo = _CategoriaRepoStub(true);
      final userRepo = _UserRepoStub(User.crear(id: 'u', nombre: 'U', email: 'u@u.com', rol: UserRole.normal));
      final validator = _ContenidoValidatorFake();
      final usecase = CrearRelatoUseCase(repo, catRepo, userRepo, validator);

      final result = await usecase.execute(titulo: 'T', contenido: 'Contenido válido', autorId: 'u', categoriaId: 'c');
      expect(result.isSuccess, isTrue);
      expect(repo.ultimo, isNotNull);
    });

    test('falla usuario invitado', () async {
      final repo = _RelatoRepoStub();
      final catRepo = _CategoriaRepoStub(true);
      final userRepo = _UserRepoStub(User.crear(id: 'u', nombre: 'U', email: 'u@u.com', rol: UserRole.invitado));
      final validator = _ContenidoValidatorFake();
      final usecase = CrearRelatoUseCase(repo, catRepo, userRepo, validator);

      final result = await usecase.execute(titulo: 'T', contenido: 'Contenido válido', autorId: 'u', categoriaId: 'c');
      expect(result.isFailure, isTrue);
    });
  });
}
