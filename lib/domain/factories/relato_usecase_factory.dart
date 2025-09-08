import 'package:get_it/get_it.dart';

import '../repositories/relato_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/categoria_repository.dart';
import '../validators/contenido_validator.dart';

import '../usecases/relatos/crear_relato_usecase.dart';
import '../usecases/relatos/actualizar_relato_usecase.dart';
import '../usecases/relatos/eliminar_relato_usecase.dart';
import '../usecases/relatos/moderar_relato_usecase.dart';
import '../usecases/relatos/reportar_relato_usecase.dart';
import '../usecases/relatos/obtener_relatos_usecase.dart';
import '../usecases/relatos/dar_like_relato_usecase.dart';
import '../usecases/relatos/registrar_compartido_relato_usecase.dart';

/// Factory para construir casos de uso relacionados con Relatos
class RelatoUseCaseFactory {
  final IRelatoRepository _relatoRepository;
  final IUserRepository _userRepository;
  final ICategoriaRepository _categoriaRepository;
  final ContenidoValidator _validator;

  RelatoUseCaseFactory({
    IRelatoRepository? relatoRepository,
    IUserRepository? userRepository,
    ICategoriaRepository? categoriaRepository,
    ContenidoValidator? validator,
    GetIt? getIt,
  })  : _relatoRepository = relatoRepository ?? (getIt ?? GetIt.I)<IRelatoRepository>(),
        _userRepository = userRepository ?? (getIt ?? GetIt.I)<IUserRepository>(),
        _categoriaRepository = categoriaRepository ?? (getIt ?? GetIt.I)<ICategoriaRepository>(),
        _validator = validator ?? (getIt ?? GetIt.I)<ContenidoValidator>();

  CrearRelatoUseCase get crear => CrearRelatoUseCase(
        _relatoRepository,
        _categoriaRepository,
        _userRepository,
        _validator,
      );

  ActualizarRelatoUseCase get actualizar => ActualizarRelatoUseCase(
        _relatoRepository,
        _categoriaRepository,
        _userRepository,
        _validator,
      );

  EliminarRelatoUseCase get eliminar => EliminarRelatoUseCase(
        _relatoRepository,
        _userRepository,
      );

  ModerarRelatoUseCase get moderar => ModerarRelatoUseCase(
        _relatoRepository,
        _userRepository,
      );

  ReportarRelatoUseCase get reportar => ReportarRelatoUseCase(
        _relatoRepository,
        _userRepository,
      );

  ObtenerRelatosUseCase get obtener => ObtenerRelatosUseCase(_relatoRepository);

  DarLikeRelatoUseCase get like => DarLikeRelatoUseCase(_relatoRepository);

  RegistrarCompartidoRelatoUseCase get compartir => RegistrarCompartidoRelatoUseCase(_relatoRepository);
}


