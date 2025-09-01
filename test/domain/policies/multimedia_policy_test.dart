import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/policies/multimedia_policy.dart';

void main() {
  group('MultimediaPolicy', () {
    test('tamanoPermitido permite null o tamaño bajo el límite', () {
      expect(MultimediaPolicy.tamanoPermitido(null), isTrue);
      expect(MultimediaPolicy.tamanoPermitido(1024 * 1024), isTrue);
    });

    test('cantidadPermitida impone máximo por contenido', () {
      expect(MultimediaPolicy.cantidadPermitida(5), isTrue);
      expect(MultimediaPolicy.cantidadPermitida(15), isFalse);
    });

    test('urlSoportada detecta extensiones válidas', () {
      expect(MultimediaPolicy.urlSoportada('https://cdn.example.com/foto.jpg'), isTrue);
      expect(MultimediaPolicy.urlSoportada('https://cdn.example.com/archivo.xyz'), isFalse);
    });
  });
}
