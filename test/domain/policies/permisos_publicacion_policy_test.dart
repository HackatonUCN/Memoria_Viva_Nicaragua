import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/policies/permisos_policy.dart';
import 'package:memoria_viva_nicaragua/domain/policies/publicacion_policy.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';
import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';
import 'package:memoria_viva_nicaragua/domain/entities/saber_popular.dart';

void main() {
  group('PermisosPolicy/PublicacionPolicy', () {
    final admin = User.crear(id: 'a', nombre: 'Admin', email: 'a@a.com', rol: UserRole.admin);
    final normal = User.crear(id: 'n', nombre: 'Normal', email: 'n@n.com', rol: UserRole.normal);
    final invitado = User.crear(id: 'i', nombre: 'Inv', email: 'i@i.com', rol: UserRole.invitado);

    test('admin puede crear y editar contenidos ajenos', () {
      final r = Relato.crear(
        titulo: 'T',
        contenido: 'Contenido largo válido',
        autorId: 'n',
        autorNombre: 'Normal',
        categoriaId: 'c1',
        categoriaNombre: 'Cat',
      );
      expect(PermisosPolicy.puedeCrearRelato(admin), isTrue);
      expect(PermisosPolicy.puedeEditarRelato(admin, r), isTrue);
    });

    test('usuario normal no puede editar contenidos de otros', () {
      final r = Relato.crear(
        titulo: 'T',
        contenido: 'Contenido largo válido',
        autorId: 'otro',
        autorNombre: 'Otro',
        categoriaId: 'c1',
        categoriaNombre: 'Cat',
      );
      expect(PermisosPolicy.puedeEditarRelato(normal, r), isFalse);
    });

    test('invitado no puede publicar', () {
      expect(PermisosPolicy.puedePublicar(invitado), isFalse);
    });

    test('PublicacionPolicy valida mínimos de título y contenido en relato/saber', () {
      final relatoOk = Relato.crear(
        titulo: 'Okay',
        contenido: 'Contenido suficiente',
        autorId: normal.id,
        autorNombre: normal.nombre,
        categoriaId: 'c1',
        categoriaNombre: 'Cat',
      );
      expect(PublicacionPolicy.puedePublicarRelato(autor: normal, relato: relatoOk), isTrue);

      final saberOk = SaberPopular.crear(
        titulo: 'Okay',
        contenido: 'Contenido suficiente',
        autorId: normal.id,
        autorNombre: normal.nombre,
        categoriaId: 'c1',
        categoriaNombre: 'Cat',
      );
      expect(PublicacionPolicy.puedePublicarSaber(autor: normal, saber: saberOk), isTrue);

      final relatoCorto = Relato.crear(
        titulo: 'A',
        contenido: 'x',
        autorId: normal.id,
        autorNombre: normal.nombre,
        categoriaId: 'c1',
        categoriaNombre: 'Cat',
      );
      expect(PublicacionPolicy.puedePublicarRelato(autor: normal, relato: relatoCorto), isFalse);
    });
  });
}
