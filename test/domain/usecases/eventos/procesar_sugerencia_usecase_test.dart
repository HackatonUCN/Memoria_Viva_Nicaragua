import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/eventos/procesar_sugerencia_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/evento_cultural_repository.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/user_repository.dart';
import 'package:memoria_viva_nicaragua/domain/entities/evento_cultural.dart';
import 'package:memoria_viva_nicaragua/domain/entities/user.dart';
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';
import 'package:memoria_viva_nicaragua/domain/enums/tipos_evento.dart';
import 'package:memoria_viva_nicaragua/domain/value_objects/ubicacion.dart';

class _EventoRepoStub implements IEventoCulturalRepository {
  SugerenciaEvento? sugerencia;
  EventoCultural? eventoGuardado;
  bool aprobada = false;
  bool rechazada = false;

  _EventoRepoStub(this.sugerencia);

  @override
  Future<SugerenciaEvento?> obtenerSugerenciaPorId(String id) async => sugerencia;
  @override
  Future<void> guardarEvento(EventoCultural evento) async { eventoGuardado = evento; }
  @override
  Future<void> aprobarSugerencia({required String sugerenciaId, required String adminId}) async { aprobada = true; }
  @override
  Future<void> rechazarSugerencia({required String sugerenciaId, required String razon, required String adminId}) async { rechazada = true; }
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserRepoStub implements IUserRepository {
  final User? user;
  _UserRepoStub(this.user);
  @override
  Future<User?> obtenerUsuarioPorId(String id) async => user;
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SugerenciaEvento _sugerencia() => SugerenciaEvento.crear(
  nombre: 'Feria', descripcion: 'Desc', tipo: TipoEvento.feria,
  categoriaId: 'c', categoriaNombre: 'Cat',
  ubicacion: Ubicacion(latitud: 12.136389, longitud: -86.251389, departamento: 'Managua', municipio: 'Managua'),
  fechaInicio: DateTime.now().toUtc().add(const Duration(days: 3)),
  fechaFin: DateTime.now().toUtc().add(const Duration(days: 4)),
  organizador: 'Org', sugeridoPorId: 'u', sugeridoPorNombre: 'User',
);

void main() {
  group('ProcesarSugerenciaUseCase', () {
    test('aprobar crea evento y marca sugerencia aprobada', () async {
      final repo = _EventoRepoStub(_sugerencia());
      final userRepo = _UserRepoStub(User.crear(id: 'a', nombre: 'Admin', email: 'a@a.com', rol: UserRole.admin));
      final usecase = ProcesarSugerenciaUseCase(repo, userRepo);

      final result = await usecase.execute(adminId: 'a', sugerenciaId: 's1', aprobar: true);
      expect(result.isSuccess, isTrue);
      expect(repo.eventoGuardado, isNotNull);
      expect(repo.aprobada, isTrue);
    });

    test('rechazar requiere razón no vacía', () async {
      final repo = _EventoRepoStub(_sugerencia());
      final userRepo = _UserRepoStub(User.crear(id: 'a', nombre: 'Admin', email: 'a@a.com', rol: UserRole.admin));
      final usecase = ProcesarSugerenciaUseCase(repo, userRepo);

      final result = await usecase.execute(adminId: 'a', sugerenciaId: 's1', aprobar: false, razonRechazo: '');
      expect(result.isFailure, isTrue);
    });
  });
}
