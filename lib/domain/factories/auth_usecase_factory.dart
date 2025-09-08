import 'package:get_it/get_it.dart';

import '../repositories/user_repository.dart';
import '../services/i_analytics_service.dart';
import '../usecases/auth/get_current_user_usecase.dart';
import '../usecases/auth/login_with_email_usecase.dart';
import '../usecases/auth/login_with_google_usecase.dart';
import '../usecases/auth/register_user_usecase.dart';
import '../usecases/auth/logout_usecase.dart';

/// Factory para construir casos de uso de autenticación con sus dependencias
class AuthUseCaseFactory {
  final IUserRepository _userRepository;
  final IAnalyticsService _analyticsService;

  AuthUseCaseFactory({
    IUserRepository? userRepository,
    IAnalyticsService? analyticsService,
    GetIt? getIt,
  })  : _userRepository = userRepository ?? (getIt ?? GetIt.I)<IUserRepository>(),
        _analyticsService = analyticsService ?? (getIt ?? GetIt.I)<IAnalyticsService>();

  GetCurrentUserUseCase get getCurrentUser => GetCurrentUserUseCase(_userRepository);

  LoginWithEmailUseCase get loginWithEmail => LoginWithEmailUseCase(_userRepository);

  LoginWithGoogleUseCase get loginWithGoogle => LoginWithGoogleUseCase(_userRepository);

  RegisterUserUseCase get registerUser => RegisterUserUseCase(_userRepository);

  LogoutUseCase get logout => LogoutUseCase(_userRepository);
}


