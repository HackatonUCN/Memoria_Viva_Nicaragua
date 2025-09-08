import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memoria_viva_nicaragua/data/models/user_model.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart' as domain;
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';

void main() {
  group('UserModel', () {
    late Map<String, dynamic> fullMap;
    late Map<String, dynamic> partialMap;
    final now = DateTime.now().toUtc();

    setUp(() {
      fullMap = {
        'id': 'u1',
        'nombre': 'Juan Pérez',
        'email': 'juan@example.com',
        'rol': 'admin',
        'avatarUrl': 'https://example.com/a.png',
        'fechaRegistro': Timestamp.fromDate(DateTime.utc(2020, 1, 1)),
        'ultimaModificacion': Timestamp.fromDate(DateTime.utc(2020, 1, 2)),
        'departamento': 'Managua',
        'municipio': 'Distrito I',
        'biografia': 'Bio',
        'activo': true,
        'relatosPublicados': 3,
        'saberesCompartidos': 5,
        'puntajeTotal': 10,
        'notificacionesActivas': false,
      };

      partialMap = {
        'id': 'u2',
        'nombre': 'Ana',
        'email': 'ana@example.com',
        'rol': 'normal',
        'fechaRegistro': Timestamp.fromDate(now),
        'ultimaModificacion': Timestamp.fromDate(now),
        'activo': false,
        // Campos opcionales ausentes para verificar defaults
      };
    });

    group('fromFirestore', () {
      test('crea modelo correctamente con datos completos', () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('users').doc('u1').set(fullMap);
        final doc = await firestore.collection('users').doc('u1').get();

        final model = UserModel.fromFirestore(doc);
        expect(model.id, 'u1');
        expect(model.nombre, 'Juan Pérez');
        expect(model.email, 'juan@example.com');
        expect(model.rol, 'admin');
        expect(model.avatarUrl, 'https://example.com/a.png');
        expect(model.departamento, 'Managua');
        expect(model.municipio, 'Distrito I');
        expect(model.biografia, 'Bio');
        expect(model.activo, isTrue);
        expect(model.relatosPublicados, 3);
        expect(model.saberesCompartidos, 5);
        expect(model.puntajeTotal, 10);
        expect(model.notificacionesActivas, isFalse);
      });

      test('maneja campos opcionales nulos/ausentes con defaults', () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('users').doc('u2').set(partialMap);
        final doc = await firestore.collection('users').doc('u2').get();

        final model = UserModel.fromFirestore(doc);
        expect(model.avatarUrl, isNull);
        expect(model.departamento, isNull);
        expect(model.municipio, isNull);
        expect(model.biografia, isNull);
        expect(model.relatosPublicados, 0);
        expect(model.saberesCompartidos, 0);
        expect(model.puntajeTotal, 0);
        expect(model.notificacionesActivas, isTrue);
      });

      test('usa doc.id cuando falta id en datos', () async {
        final firestore = FakeFirebaseFirestore();
        final dataSinId = Map<String, dynamic>.from(partialMap)..remove('id');
        await firestore.collection('users').doc('Z9').set(dataSinId);
        final doc = await firestore.collection('users').doc('Z9').get();
        final model = UserModel.fromFirestore(doc);
        expect(model.id, 'Z9');
      });

      test('lanza excepción para datos inválidos (tipos incorrectos)', () {
        final invalid = {
          ...partialMap,
          'id': null, // requerido como String
        };
        expect(() => UserModel.fromMap(invalid), throwsA(isA<TypeError>()));
      });
    });

    group('toFirestore', () {
      test('serializa todos los campos correctamente', () {
        final model = UserModel.fromMap(fullMap);
        final map = model.toMap();
        expect(map['id'], 'u1');
        expect(map['nombre'], 'Juan Pérez');
        expect(map['email'], 'juan@example.com');
        expect(map['rol'], 'admin');
        expect(map['avatarUrl'], 'https://example.com/a.png');
        expect(map['fechaRegistro'], isA<Timestamp>());
        expect(map['ultimaModificacion'], isA<Timestamp>());
        expect(map['activo'], true);
        expect(map['relatosPublicados'], 3);
        expect(map['saberesCompartidos'], 5);
        expect(map['puntajeTotal'], 10);
        expect(map['notificacionesActivas'], false);
      });

      test('maneja campos nulos apropiadamente', () {
        final model = UserModel.fromMap(partialMap);
        final map = model.toMap();
        expect(map['avatarUrl'], isNull);
        expect(map['departamento'], isNull);
        expect(map['municipio'], isNull);
        expect(map['biografia'], isNull);
      });
    });

    group('conversión con entidad', () {
      test('convierte a entidad sin pérdida de datos', () {
        final model = UserModel.fromMap(fullMap);
        final entity = model.toDomain();
        expect(entity.id, model.id);
        expect(entity.nombre, model.nombre);
        expect(entity.email, model.email);
        expect(entity.rol.value, model.rol);
        expect(entity.avatarUrl, model.avatarUrl);
        expect(entity.departamento, model.departamento);
        expect(entity.municipio, model.municipio);
        expect(entity.biografia, model.biografia);
        expect(entity.activo, model.activo);
        expect(entity.relatosPublicados, model.relatosPublicados);
        expect(entity.saberesCompartidos, model.saberesCompartidos);
        expect(entity.puntajeTotal, model.puntajeTotal);
        expect(entity.notificacionesActivas, model.notificacionesActivas);
      });

      test('convierte desde entidad correctamente', () {
        final entity = domain.User(
          id: 'u123',
          nombre: 'Nombre Apellido',
          email: 'test@example.com',
          rol: UserRole.admin,
          avatarUrl: null,
          fechaRegistro: DateTime.utc(2021, 1, 1),
          ultimaModificacion: DateTime.utc(2021, 1, 2),
          departamento: null,
          municipio: null,
          biografia: null,
          activo: true,
          relatosPublicados: 0,
          saberesCompartidos: 0,
          puntajeTotal: 0,
          notificacionesActivas: true,
        );
        final model = UserModel.fromDomain(entity);
        expect(model.id, entity.id);
        expect(model.nombre, entity.nombre);
        expect(model.email, entity.email);
        expect(model.rol, entity.rol.value);
        expect(model.fechaRegistro, isA<Timestamp>());
        expect(model.ultimaModificacion, isA<Timestamp>());
      });
    });

    group('casos extremos', () {
      test('maneja strings muy largos y caracteres especiales', () {
        final long = 'a' * 5000 + 'ñáéíóú@!#%&/()';
        final model = UserModel(
          id: 'uL',
          nombre: long,
          email: 'largo@example.com',
          rol: 'normal',
          avatarUrl: null,
          fechaRegistro: Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)),
          ultimaModificacion: Timestamp.fromDate(DateTime.utc(9999, 12, 31)),
          activo: true,
        );
        expect(model.nombre.length, greaterThan(5000));
      });

      test('maneja fechas extremas y timestamps', () {
        final model = UserModel.fromMap({
          'id': 'ux',
          'nombre': 'X',
          'email': 'x@example.com',
          'rol': 'invitado',
          'fechaRegistro': Timestamp.fromMillisecondsSinceEpoch(0),
          'ultimaModificacion': Timestamp.fromDate(DateTime.utc(9999, 12, 31)),
          'activo': false,
        });
        final entity = model.toDomain();
        expect(entity.fechaRegistro.isUtc, isTrue);
        expect(entity.ultimaModificacion.isUtc, isTrue);
      });
    });

    group('validaciones de datos', () {
      test('lanza excepción por email inválido en entidad', () {
        expect(
          () => domain.User(
            id: 'u',
            nombre: 'N',
            email: 'invalido',
            rol: UserRole.normal,
            fechaRegistro: DateTime.now().toUtc(),
            ultimaModificacion: DateTime.now().toUtc(),
            activo: true,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });
}


