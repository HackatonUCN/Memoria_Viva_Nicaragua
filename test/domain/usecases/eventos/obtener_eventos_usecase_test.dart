import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/eventos/obtener_eventos_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/evento_cultural_repository.dart';
import 'package:memoria_viva_nicaragua/domain/entities/evento_cultural.dart';
import 'package:memoria_viva_nicaragua/domain/enums/tipos_evento.dart';
import 'package:memoria_viva_nicaragua/domain/value_objects/ubicacion.dart';

class _EventoRepoListStub implements IEventoCulturalRepository {
  final List<EventoCultural> lista;
  _EventoRepoListStub(this.lista);
  @override
  Future<List<EventoCultural>> obtenerEventos() async => lista;
  @override
  Future<List<EventoCultural>> obtenerEventosPorCategoria(String categoriaId) async => lista;
  @override
  Future<List<EventoCultural>> obtenerEventosPorTipo(TipoEvento tipo) async => lista;
  @override
  Future<List<EventoCultural>> obtenerEventosPorFecha(DateTime fecha) async => lista;
  @override
  Future<List<EventoCultural>> obtenerEventosPorRangoFecha({required DateTime inicio, required DateTime fin}) async => lista;
  @override
  Future<List<EventoCultural>> obtenerEventosPorUbicacion({String? departamento, String? municipio}) async => lista;
  @override
  Future<List<EventoCultural>> obtenerEventosCercanos({required double latitud, required double longitud, required double radioKm}) async => lista;
  @override
  Future<List<EventoCultural>> buscarEventos(String texto) async => lista;
  @override
  Stream<List<EventoCultural>> observarEventos() => Stream.value(lista);
  @override
  Stream<List<EventoCultural>> observarEventosPorCategoria(String categoriaId) => Stream.value(lista);
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

EventoCultural _evento() => EventoCultural.crear(
  nombre: 'Feria', descripcion: 'Desc', tipo: TipoEvento.feria,
  categoriaId: 'c', categoriaNombre: 'Cat',
  ubicacion: Ubicacion(latitud: 12.136389, longitud: -86.251389, departamento: 'Managua', municipio: 'Managua'),
  fechaInicio: DateTime.now().toUtc().add(const Duration(days: 3)),
  fechaFin: DateTime.now().toUtc().add(const Duration(days: 4)),
  organizador: 'Org', creadoPorId: 'a', creadoPorNombre: 'Admin',
);

void main() {
  group('ObtenerEventosUseCase', () {
    test('execute retorna lista', () async {
      final repo = _EventoRepoListStub([_evento()]);
      final usecase = ObtenerEventosUseCase(repo);
      final result = await usecase.execute();
      expect(result.isSuccess, isTrue);
    });

    test('porCategoria retorna lista', () async {
      final repo = _EventoRepoListStub([_evento()]);
      final usecase = ObtenerEventosUseCase(repo);
      final result = await usecase.porCategoria('c');
      expect(result.isSuccess, isTrue);
    });

    test('porTipo retorna lista', () async {
      final repo = _EventoRepoListStub([_evento()]);
      final usecase = ObtenerEventosUseCase(repo);
      final result = await usecase.porTipo(TipoEvento.feria);
      expect(result.isSuccess, isTrue);
    });

    test('porFecha retorna lista', () async {
      final repo = _EventoRepoListStub([_evento()]);
      final usecase = ObtenerEventosUseCase(repo);
      final result = await usecase.porFecha(DateTime.now().toUtc());
      expect(result.isSuccess, isTrue);
    });

    test('porRangoFecha retorna lista', () async {
      final repo = _EventoRepoListStub([_evento()]);
      final usecase = ObtenerEventosUseCase(repo);
      final now = DateTime.now().toUtc();
      final result = await usecase.porRangoFecha(inicio: now, fin: now.add(const Duration(days: 7)));
      expect(result.isSuccess, isTrue);
    });

    test('porUbicacion retorna lista', () async {
      final repo = _EventoRepoListStub([_evento()]);
      final usecase = ObtenerEventosUseCase(repo);
      final result = await usecase.porUbicacion(departamento: 'Managua');
      expect(result.isSuccess, isTrue);
    });

    test('cercanos retorna lista', () async {
      final repo = _EventoRepoListStub([_evento()]);
      final usecase = ObtenerEventosUseCase(repo);
      final result = await usecase.cercanos(latitud: 12.1, longitud: -86.2, radioKm: 5);
      expect(result.isSuccess, isTrue);
    });

    test('buscar retorna lista', () async {
      final repo = _EventoRepoListStub([_evento()]);
      final usecase = ObtenerEventosUseCase(repo);
      final result = await usecase.buscar('feria');
      expect(result.isSuccess, isTrue);
    });

    test('observe emite lista', () async {
      final repo = _EventoRepoListStub([_evento()]);
      final usecase = ObtenerEventosUseCase(repo);
      final items = await usecase.observe().first;
      expect(items, isNotEmpty);
    });
  });
}
