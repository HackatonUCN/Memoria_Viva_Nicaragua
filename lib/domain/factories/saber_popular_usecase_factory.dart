import 'package:get_it/get_it.dart';

import '../repositories/saber_popular_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/categoria_repository.dart';
import '../validators/contenido_validator.dart';

import '../usecases/saberes/crear_saber_usecase.dart';
import '../usecases/saberes/actualizar_saber_usecase.dart';
import '../usecases/saberes/eliminar_saber_usecase.dart';
import '../usecases/saberes/moderar_saber_usecase.dart';
import '../usecases/saberes/obtener_saberes_usecase.dart';

/// Factory para construir casos de uso relacionados con Saberes Populares
class SaberPopularUseCaseFactory {
  final ISaberPopularRepository _saberRepository;
  final IUserRepository _userRepository;
  final ICategoriaRepository _categoriaRepository;
  final ContenidoValidator _validator;

  SaberPopularUseCaseFactory({
    ISaberPopularRepository? saberRepository,
    IUserRepository? userRepository,
    ICategoriaRepository? categoriaRepository,
    ContenidoValidator? validator,
    GetIt? getIt,
  })  : _saberRepository = saberRepository ?? (getIt ?? GetIt.I)<ISaberPopularRepository>(),
        _userRepository = userRepository ?? (getIt ?? GetIt.I)<IUserRepository>(),
        _categoriaRepository = categoriaRepository ?? (getIt ?? GetIt.I)<ICategoriaRepository>(),
        _validator = validator ?? (getIt ?? GetIt.I)<ContenidoValidator>();

  CrearSaberUseCase get crear => CrearSaberUseCase(
        _saberRepository,
        _categoriaRepository,
        _userRepository,
        _validator,
      );

  ActualizarSaberUseCase get actualizar => ActualizarSaberUseCase(
        _saberRepository,
        _categoriaRepository,
        _userRepository,
        _validator,
      );

  EliminarSaberUseCase get eliminar => EliminarSaberUseCase(
        _saberRepository,
        _userRepository,
      );

  ModerarSaberUseCase get moderar => ModerarSaberUseCase(
        _saberRepository,
        _userRepository,
      );

  ObtenerSaberesUseCase get obtener => ObtenerSaberesUseCase(_saberRepository);
}


