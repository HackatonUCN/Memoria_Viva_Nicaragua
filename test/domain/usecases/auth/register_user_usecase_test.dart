import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/auth/register_user_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';

class _UserRepositoryStub implements IUserRepository {
  bool emailExiste;
  _UserRepositoryStub({this.emailExiste = false});

  @override
  Future<bool> verificarEmailExiste(String email) async => emailExiste;

  @override
  Future<User> registrarEmail({required String email, required String password, required String nombre}) async {
    return User.crear(id: 'newid', nombre: nombre, email: email, rol: UserRole.normal);
  }

  @override
  Future<void> enviarEmailVerificacion() async {}

  // Resto de métodos no usados
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('RegisterUserUseCase', () {
    test('falla cuando el email ya existe', () async {
      final repo = _UserRepositoryStub(emailExiste: true);
      final usecase = RegisterUserUseCase(repo);
      final result = await usecase.execute(email: 'a@a.com', password: 'Passw0rd!', nombre: 'Ana');
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isNotNull);
    });

    test('éxito cuando email no existe', () async {
      final repo = _UserRepositoryStub(emailExiste: false);
      final usecase = RegisterUserUseCase(repo);
      final result = await usecase.execute(email: 'b@b.com', password: 'Passw0rd!', nombre: 'Beto');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.email, 'b@b.com');
    });
  });
}
