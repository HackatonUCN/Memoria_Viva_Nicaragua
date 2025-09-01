import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/failures/exception_mapper.dart';
import 'package:memoria_viva_nicaragua/domain/failures/failures.dart';
import 'package:memoria_viva_nicaragua/domain/exceptions/auth_exception.dart';

void main() {
  group('mapExceptionToFailure', () {
    test('InvalidCredentialsException -> ValidationFailure', () {
      final f = mapExceptionToFailure(InvalidCredentialsException());
      expect(f, isA<ValidationFailure>());
      expect(f.code, 'INVALID_CREDENTIALS');
    });

    test('UserNotFoundException -> NotFoundFailure', () {
      final f = mapExceptionToFailure(UserNotFoundException());
      expect(f, isA<NotFoundFailure>());
      expect(f.code, 'USER_NOT_FOUND');
    });

    test('NetworkException -> NetworkFailure', () {
      final f = mapExceptionToFailure(NetworkException());
      expect(f, isA<NetworkFailure>());
      expect(f.code, 'NETWORK_ERROR');
    });

    test('desconocida -> UnexpectedFailure', () {
      final f = mapExceptionToFailure(StateError('oops'));
      expect(f, isA<UnexpectedFailure>());
      expect(f.code, 'UNEXPECTED_ERROR');
    });
  });
}
