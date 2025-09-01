import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/value_objects/multimedia.dart';
import 'package:memoria_viva_nicaragua/domain/exceptions/value_object_exception.dart';

void main() {
  group('Multimedia', () {
    test('crea multimedia imagen válida y genera thumbnail', () {
      final m = Multimedia(url: 'https://cdn.example.com/foto.jpg');
      expect(m.tipo, TipoMultimedia.imagen);
      final thumb = m.obtenerThumbnailUrl();
      expect(thumb.endsWith('_thumb.jpg'), isTrue);
    });

    test('lanza por URL inválida', () {
      expect(
        () => Multimedia(url: 'http://inseguro.com/foto.jpg'),
        throwsA(isA<MultimediaInvalidaException>()),
      );
    });

    test('lanza por extensión no soportada', () {
      expect(
        () => Multimedia(url: 'https://cdn.example.com/archivo.xyz'),
        throwsA(isA<MultimediaInvalidaException>()),
      );
    });

    test('respeta límite de descripción', () {
      final desc = 'a' * (Multimedia.MAX_DESCRIPCION_LENGTH + 1);
      expect(
        () => Multimedia(url: 'https://cdn.example.com/foto.jpg', descripcion: desc),
        throwsA(isA<MultimediaInvalidaException>()),
      );
    });
  });
}
