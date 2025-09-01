import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/eventos/buscar_eventos_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/evento_cultural_repository.dart';
import 'package:memoria_viva_nicaragua/domain/entities/evento_cultural.dart';
import 'package:memoria_viva_nicaragua/domain/enums/tipos_evento.dart';
import 'package:memoria_viva_nicaragua/domain/value_objects/ubicacion.dart';

class _EventoRepoStub implements IEventoCulturalRepository {
  final List<EventoCultural> lista;
  _EventoRepoStub(this.lista);
  @override
  Future<List<EventoCultural>> buscarEventos(String texto) async => lista;
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
  group('BuscarEventosUseCase', () {
    test('texto vacío retorna lista vacía', () async {
      final repo = _EventoRepoStub([]);
      final usecase = BuscarEventosUseCase(repo);
      final result = await usecase.execute('   ');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('búsqueda normal retorna lista', () async {
      final repo = _EventoRepoStub([_evento()]);
      final usecase = BuscarEventosUseCase(repo);
      final result = await usecase.execute('feria');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNotEmpty);
    });
  });
}
