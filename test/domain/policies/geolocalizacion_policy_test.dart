import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/policies/geolocalizacion_policy.dart';
import 'package:memoria_viva_nicaragua/domain/value_objects/ubicacion.dart';

void main() {
  group('GeolocalizacionPolicy', () {
    test('estaDentroDeNicaragua true para Managua', () {
      final u = Ubicacion(
        latitud: 12.136389,
        longitud: -86.251389,
        departamento: 'Managua',
        municipio: 'Managua',
      );
      expect(GeolocalizacionPolicy.estaDentroDeNicaragua(u), isTrue);
    });

    test('estaCercaDe dentro de 5km', () {
      final a = Ubicacion(
        latitud: 12.136389,
        longitud: -86.251389,
        departamento: 'Managua',
        municipio: 'Managua',
      );
      final b = Ubicacion(
        latitud: 12.140000,
        longitud: -86.250000,
        departamento: 'Managua',
        municipio: 'Managua',
      );
      expect(GeolocalizacionPolicy.estaCercaDe(a: a, b: b, km: 5), isTrue);
    });
  });
}
