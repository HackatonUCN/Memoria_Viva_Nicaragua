import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/value_objects/ubicacion.dart';
import 'package:memoria_viva_nicaragua/domain/exceptions/value_object_exception.dart';

void main() {
  group('Ubicacion', () {
    test('crea ubicación válida dentro de Nicaragua', () {
      final ubicacion = Ubicacion(
        latitud: 12.136389,
        longitud: -86.251389,
        departamento: 'Managua',
        municipio: 'Managua',
      );
      expect(ubicacion.departamento, 'Managua');
      expect(ubicacion.municipio, 'Managua');
    });

    test('lanza fuera de Nicaragua', () {
      expect(
        () => Ubicacion(
          latitud: 20.0,
          longitud: -86.0,
          departamento: 'Managua',
          municipio: 'Managua',
        ),
        throwsA(isA<UbicacionInvalidaException>()),
      );
    });

    test('lanza municipio no pertenece a departamento', () {
      expect(
        () => Ubicacion(
          latitud: 12.5,
          longitud: -86.2,
          departamento: 'León',
          municipio: 'Masaya',
        ),
        throwsA(isA<UbicacionInvalidaException>()),
      );
    });

    test('calcula distancia aproximada (Haversine)', () {
      final a = Ubicacion(
        latitud: 12.136389,
        longitud: -86.251389,
        departamento: 'Managua',
        municipio: 'Managua',
      );
      final b = Ubicacion(
        latitud: 12.4379,
        longitud: -86.8780,
        departamento: 'León',
        municipio: 'León',
      );
      final distancia = a.calcularDistanciaA(b);
      expect(distancia, greaterThan(60));
      expect(distancia, lessThan(120));
    });
  });
}
