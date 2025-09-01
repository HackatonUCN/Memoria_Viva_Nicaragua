import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/auth/login_with_google_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';

class _UserRepositoryFake implements IUserRepository {
  final bool failNetwork;
  _UserRepositoryFake({this.failNetwork = false});

  @override
  Future<User> iniciarSesionGoogle() async {
    if (failNetwork) throw Exception('network-error');
    return User.crear(
      id: 'uid123',
      nombre: 'Juan',
      email: 'juan@example.com',
      rol: UserRole.normal,
    );
  }

  // Métodos no usados en estas pruebas
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('LoginWithGoogleUseCase', () {
    test('retorna Success con usuario', () async {
      final repo = _UserRepositoryFake();
      final usecase = LoginWithGoogleUseCase(repo);
      final result = await usecase.execute();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.email, 'juan@example.com');
    });

    test('retorna FailureResult en error de red', () async {
      final repo = _UserRepositoryFake(failNetwork: true);
      final usecase = LoginWithGoogleUseCase(repo);
      final result = await usecase.execute();
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isNotNull);
    });
  });
}
