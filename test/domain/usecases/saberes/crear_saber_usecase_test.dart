import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/saberes/crear_saber_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/saber_popular_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/categoria_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/validators/contenido_validator.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';
import 'package:memoria_viva_nicaragua/domain/entities/saber_popular.dart';
import 'package:memoria_viva_nicaragua/domain/entities/categoria.dart';
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';
import 'package:memoria_viva_nicaragua/domain/enums/tipos_contenido.dart';

class _SaberRepoStub implements ISaberPopularRepository {
  List<SaberPopular> guardados = [];
  bool haySimilar = false;
  @override
  Future<void> guardarSaber(SaberPopular saber) async { guardados.add(saber); }
  @override
  Future<List<SaberPopular>> buscarSaberesSimilares({required String titulo, required String categoriaId}) async {
    return haySimilar ? [SaberPopular.crear(titulo: titulo, contenido: 'x', autorId: 'a', autorNombre: 'A', categoriaId: categoriaId, categoriaNombre: 'Cat')] : [];
  }
  // No usados:
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CategoriaRepoStub implements ICategoriaRepository {
  final bool existe;
  _CategoriaRepoStub({required this.existe});
  @override
  Future<Categoria?> obtenerCategoriaPorId(String id) async => existe
      ? Categoria.crear(
          nombre: 'Cat',
          descripcion: 'desc',
          tipo: TipoContenido.saber,
          icono: 'i',
          color: '#FFFFFF',
          orden: 0,
        )
      : null;
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserRepoStub implements IUserRepository {
  final User? user;
  _UserRepoStub({required this.user});
  @override
  Future<User?> obtenerUsuarioPorId(String id) async => user;
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ContenidoValidatorFake implements ContenidoValidator {
  @override
  void validarSaberPopular(SaberPopular saber) { /* válido */ }
  // No usados
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CrearSaberUseCase', () {
    test('crea saber exitosamente', () async {
      final saberRepo = _SaberRepoStub();
      final categoriaRepo = _CategoriaRepoStub(existe: true);
      final userRepo = _UserRepoStub(user: User.crear(id: 'u1', nombre: 'Ana', email: 'a@a.com', rol: UserRole.normal));
      final validator = _ContenidoValidatorFake();
      final usecase = CrearSaberUseCase(saberRepo, categoriaRepo, userRepo, validator);

      final result = await usecase.execute(
        titulo: 'Titulo', contenido: 'Contenido válido', autorId: 'u1', categoriaId: 'c1', imagenesUrls: ['https://cdn/a.jpg'],
      );
      expect(result.isSuccess, isTrue);
      expect(saberRepo.guardados.length, 1);
    });

    test('falla por usuario invitado', () async {
      final saberRepo = _SaberRepoStub();
      final categoriaRepo = _CategoriaRepoStub(existe: true);
      final userRepo = _UserRepoStub(user: User.crear(id: 'u1', nombre: 'Inv', email: 'i@i.com', rol: UserRole.invitado));
      final validator = _ContenidoValidatorFake();
      final usecase = CrearSaberUseCase(saberRepo, categoriaRepo, userRepo, validator);

      final result = await usecase.execute(
        titulo: 'Titulo', contenido: 'Contenido válido', autorId: 'u1', categoriaId: 'c1',
      );
      expect(result.isFailure, isTrue);
    });

    test('falla por duplicado', () async {
      final saberRepo = _SaberRepoStub()..haySimilar = true;
      final categoriaRepo = _CategoriaRepoStub(existe: true);
      final userRepo = _UserRepoStub(user: User.crear(id: 'u1', nombre: 'Ana', email: 'a@a.com'));
      final validator = _ContenidoValidatorFake();
      final usecase = CrearSaberUseCase(saberRepo, categoriaRepo, userRepo, validator);

      final result = await usecase.execute(
        titulo: 'Titulo', contenido: 'Contenido válido', autorId: 'u1', categoriaId: 'c1',
      );
      expect(result.isFailure, isTrue);
    });
  });
}
