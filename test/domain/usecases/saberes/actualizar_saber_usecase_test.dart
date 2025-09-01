import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/saberes/actualizar_saber_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/saber_popular_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/categoria_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/validators/contenido_validator.dart';
import 'package:memoria_viva_nicaragua/domain/entities/saber_popular.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';
import 'package:memoria_viva_nicaragua/domain/entities/categoria.dart';
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';
import 'package:memoria_viva_nicaragua/domain/enums/tipos_contenido.dart';

class _SaberRepoStub implements ISaberPopularRepository {
  SaberPopular? fuente;
  SaberPopular? actualizado;
  _SaberRepoStub(this.fuente);
  @override
  Future<SaberPopular?> obtenerSaberPorId(String id) async => fuente;
  @override
  Future<void> actualizarSaber(SaberPopular saber) async { actualizado = saber; }
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CategoriaRepoStub implements ICategoriaRepository {
  @override
  Future<Categoria?> obtenerCategoriaPorId(String id) async => Categoria.crear(
    nombre: 'Cat', descripcion: 'd', tipo: TipoContenido.saber, icono: 'i', color: '#FFFFFF', orden: 0,
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
  void validarSaberPopular(SaberPopular saber) { /* válido */ }
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SaberPopular _baseSaber({required String autorId}) => SaberPopular.crear(
  titulo: 'Titulo', contenido: 'Contenido', autorId: autorId, autorNombre: 'Autor', categoriaId: 'c', categoriaNombre: 'Cat',
);

void main() {
  group('ActualizarSaberUseCase', () {
    test('actualiza saber por autor', () async {
      final fuente = _baseSaber(autorId: 'u1');
      final repo = _SaberRepoStub(fuente);
      final catRepo = _CategoriaRepoStub();
      final userRepo = _UserRepoStub(User.crear(id: 'u1', nombre: 'User', email: 'u@u.com', rol: UserRole.normal));
      final validator = _ContenidoValidatorFake();
      final usecase = ActualizarSaberUseCase(repo, catRepo, userRepo, validator);

      final result = await usecase.execute(saberId: 's1', usuarioId: 'u1', titulo: 'Nuevo');
      expect(result.isSuccess, isTrue);
      expect(repo.actualizado?.titulo, 'Nuevo');
    });

    test('falla sin permisos (otro usuario)', () async {
      final fuente = _baseSaber(autorId: 'autor');
      final repo = _SaberRepoStub(fuente);
      final catRepo = _CategoriaRepoStub();
      final userRepo = _UserRepoStub(User.crear(id: 'u2', nombre: 'Otro', email: 'o@o.com', rol: UserRole.normal));
      final validator = _ContenidoValidatorFake();
      final usecase = ActualizarSaberUseCase(repo, catRepo, userRepo, validator);

      final result = await usecase.execute(saberId: 's1', usuarioId: 'u2', titulo: 'Nuevo');
      expect(result.isFailure, isTrue);
    });
  });
}
