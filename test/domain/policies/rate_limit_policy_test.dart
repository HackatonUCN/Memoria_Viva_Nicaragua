import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/policies/rate_limit_policy.dart';

void main() {
  group('RateLimitPolicy', () {
    test('permite primeras acciones dentro del límite', () {
      int permitidas = 0;
      for (int i = 0; i < RateLimitPolicy.MAX_ACCIONES_MINUTO; i++) {
        if (RateLimitPolicy.registrarYPermitir('u1')) {
          permitidas++;
        }
      }
      expect(permitidas, RateLimitPolicy.MAX_ACCIONES_MINUTO);
    });

    test('bloquea cuando se supera el límite', () {
      bool ultimo = RateLimitPolicy.registrarYPermitir('u1');
      expect(ultimo, isFalse);
    });
  });
}
