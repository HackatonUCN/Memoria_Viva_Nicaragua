import 'package:get_it/get_it.dart';

import '../repositories/evento_cultural_repository.dart';
import '../repositories/categoria_repository.dart';
import '../repositories/user_repository.dart';
import '../validators/contenido_validator.dart';

import '../usecases/eventos/crear_evento_usecase.dart';
import '../usecases/eventos/actualizar_evento_usecase.dart';
import '../usecases/eventos/eliminar_evento_usecase.dart';
import '../usecases/eventos/obtener_eventos_usecase.dart';
import '../usecases/eventos/buscar_eventos_usecase.dart';
import '../usecases/eventos/crear_sugerencia_usecase.dart';
import '../usecases/eventos/procesar_sugerencia_usecase.dart';
import '../usecases/eventos/obtener_sugerencias_pendientes_usecase.dart';
import '../usecases/eventos/obtener_eventos_carrusel_por_categoria_usecase.dart';
import '../usecases/eventos/obtener_eventos_por_rango_y_busqueda_usecase.dart';
import '../usecases/eventos/obtener_marcadores_por_mes_usecase.dart';

/// Factory para construir casos de uso relacionados con Eventos Culturales
class EventoUseCaseFactory {
  final IEventoCulturalRepository _eventoRepository;
  final ICategoriaRepository _categoriaRepository;
  final IUserRepository _userRepository;
  final ContenidoValidator _validator;

  EventoUseCaseFactory({
    IEventoCulturalRepository? eventoRepository,
    ICategoriaRepository? categoriaRepository,
    IUserRepository? userRepository,
    ContenidoValidator? validator,
    GetIt? getIt,
  })  : _eventoRepository = eventoRepository ?? (getIt ?? GetIt.I)<IEventoCulturalRepository>(),
        _categoriaRepository = categoriaRepository ?? (getIt ?? GetIt.I)<ICategoriaRepository>(),
        _userRepository = userRepository ?? (getIt ?? GetIt.I)<IUserRepository>(),
        _validator = validator ?? (getIt ?? GetIt.I)<ContenidoValidator>();

  CrearEventoUseCase get crear => CrearEventoUseCase(
        _eventoRepository,
        _categoriaRepository,
        _userRepository,
        _validator,
      );

  ActualizarEventoUseCase get actualizar => ActualizarEventoUseCase(
        _eventoRepository,
        _categoriaRepository,
        _userRepository,
      );

  EliminarEventoUseCase get eliminar => EliminarEventoUseCase(
        _eventoRepository,
        _userRepository,
      );

  ObtenerEventosUseCase get obtener => ObtenerEventosUseCase(_eventoRepository);

  BuscarEventosUseCase get buscar => BuscarEventosUseCase(_eventoRepository);

  CrearSugerenciaUseCase get crearSugerencia => CrearSugerenciaUseCase(
        _eventoRepository,
        _categoriaRepository,
        _userRepository,
        _validator,
      );

  ProcesarSugerenciaUseCase get procesarSugerencia => ProcesarSugerenciaUseCase(
        _eventoRepository,
        _userRepository,
      );

  ObtenerSugerenciasPendientesUseCase get obtenerSugerenciasPendientes =>
      ObtenerSugerenciasPendientesUseCase(_eventoRepository);

  // Nuevos casos de uso (segmentación por componente)
  ObtenerEventosCarruselPorCategoriaUseCase get carruselPorCategoria =>
      ObtenerEventosCarruselPorCategoriaUseCase(_eventoRepository);

  ObtenerEventosPorRangoYBusquedaUseCase get porRangoYBusqueda =>
      ObtenerEventosPorRangoYBusquedaUseCase(_eventoRepository);

  ObtenerMarcadoresPorMesUseCase get marcadoresPorMes =>
      ObtenerMarcadoresPorMesUseCase(_eventoRepository);
}


