import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/relatos/actualizar_relato_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/relato_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/categoria_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/validators/contenido_validator.dart';
import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';
import 'package:memoria_viva_nicaragua/domain/entities/categoria.dart';
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';
import 'package:memoria_viva_nicaragua/domain/enums/tipos_contenido.dart';

class _RelatoRepoStub implements IRelatoRepository {
  Relato? almacenado;
  Relato? fuente;
  _RelatoRepoStub(this.fuente);
  @override
  Future<Relato?> obtenerRelatoPorId(String id) async => fuente;
  @override
  Future<void> guardarRelato(Relato relato) async { almacenado = relato; }
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CategoriaRepoStub implements ICategoriaRepository {
  @override
  Future<Categoria?> obtenerCategoriaPorId(String id) async => Categoria.crear(
    nombre: 'Cat', descripcion: 'd', tipo: TipoContenido.relato, icono: 'i', color: '#FFFFFF', orden: 0,
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
  void validarRelato(Relato relato) { /* válido */ }
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Relato _baseRelato({required String autorId}) => Relato.crear(
  titulo: 'Titulo', contenido: 'Contenido', autorId: autorId, autorNombre: 'Autor', categoriaId: 'c', categoriaNombre: 'Cat',
);

void main() {
  group('ActualizarRelatoUseCase', () {
    test('actualiza relato exitosamente por autor', () async {
      final original = _baseRelato(autorId: 'u1');
      final repo = _RelatoRepoStub(original);
      final catRepo = _CategoriaRepoStub();
      final userRepo = _UserRepoStub(User.crear(id: 'u1', nombre: 'User', email: 'u@u.com', rol: UserRole.normal));
      final validator = _ContenidoValidatorFake();
      final usecase = ActualizarRelatoUseCase(repo, catRepo, userRepo, validator);

      final result = await usecase.execute(relatoId: 'r1', usuarioId: 'u1', titulo: 'Nuevo');
      expect(result.isSuccess, isTrue);
      expect(repo.almacenado?.titulo, 'Nuevo');
    });

    test('falla sin permisos (otro usuario)', () async {
      final original = _baseRelato(autorId: 'autor');
      final repo = _RelatoRepoStub(original);
      final catRepo = _CategoriaRepoStub();
      final userRepo = _UserRepoStub(User.crear(id: 'u2', nombre: 'Otro', email: 'o@o.com', rol: UserRole.normal));
      final validator = _ContenidoValidatorFake();
      final usecase = ActualizarRelatoUseCase(repo, catRepo, userRepo, validator);

      final result = await usecase.execute(relatoId: 'r1', usuarioId: 'u2', titulo: 'Nuevo');
      expect(result.isFailure, isTrue);
    });
  });
}
