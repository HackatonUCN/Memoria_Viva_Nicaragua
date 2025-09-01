import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';

void main() {
  group('User', () {
    test('crear() inicializa con valores por defecto y UTC', () {
      final u = User.crear(
        id: 'uid123',
        nombre: 'María',
        email: 'maria@example.com',
        rol: UserRole.normal,
      );
      expect(u.activo, isTrue);
      expect(u.fechaRegistro.isUtc, isTrue);
      expect(u.ultimaModificacion.isUtc, isTrue);
    });

    test('copyWith actualiza campos y ultimaModificacion', () async {
      final u = User.crear(
        id: 'uid123',
        nombre: 'María',
        email: 'maria@example.com',
      );
      final before = u.ultimaModificacion;
      await Future.delayed(const Duration(milliseconds: 2));
      final v = u.copyWith(nombre: 'María López');
      expect(v.nombre, 'María López');
      expect(v.ultimaModificacion.isAfter(before), isTrue);
    });
  });
}
