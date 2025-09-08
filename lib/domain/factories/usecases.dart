import 'package:get_it/get_it.dart';

import 'auth_usecase_factory.dart';
import 'relato_usecase_factory.dart';
import 'saber_popular_usecase_factory.dart';
import 'evento_usecase_factory.dart';

/// Agregador de fábricas de casos de uso por dominio funcional
class UseCases {
  final AuthUseCaseFactory auth;
  final RelatoUseCaseFactory relatos;
  final SaberPopularUseCaseFactory saberes;
  final EventoUseCaseFactory eventos;

  UseCases({
    AuthUseCaseFactory? auth,
    RelatoUseCaseFactory? relatos,
    SaberPopularUseCaseFactory? saberes,
    EventoUseCaseFactory? eventos,
    GetIt? getIt,
  })  : auth = auth ?? (getIt ?? GetIt.I)<AuthUseCaseFactory>(),
        relatos = relatos ?? (getIt ?? GetIt.I)<RelatoUseCaseFactory>(),
        saberes = saberes ?? (getIt ?? GetIt.I)<SaberPopularUseCaseFactory>(),
        eventos = eventos ?? (getIt ?? GetIt.I)<EventoUseCaseFactory>();

  /// Helper para resolver rápidamente desde GetIt
  static UseCases resolve([GetIt? getIt]) => UseCases(getIt: getIt ?? GetIt.I);
}


