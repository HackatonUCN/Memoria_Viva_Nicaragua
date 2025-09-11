import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:memoria_viva_nicaragua/presentation/screens/auth/login_screen.dart';
import 'data/infrastructure/services/firebase_services_manager.dart';
import 'core/di/service_locator.dart';
import 'core/config/app_environment.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash/splash_screen.dart';
// import 'presentation/screens/home/home_screen.dart'; // No se usa actualmente
import 'presentation/bloc/splash/splash_bloc.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/navigation_provider.dart';
import 'presentation/providers/media_playback_provider.dart';
// Importamos RouteObserver para las animaciones
import 'config/app_router.dart';
import 'package:url_strategy/url_strategy.dart';
import 'core/services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // URLs limpias en Web
  setPathUrlStrategy();
  
  try {
    // Inicializa el contenedor de dependencias con manejo de entorno
    final env = AppEnvironmentMapper.fromString(const String.fromEnvironment('APP_ENV', defaultValue: 'dev'));
    await ServiceLocator.instance.initialize(environment: env);
    // Token FCM ya se gestiona al autenticarse (guardado en Firestore)
  } catch (error) {
    if (kDebugMode) {
      print('DI/Firebase initialization failed: $error');
      print('Continuing app startup...');
    }
  }

  // Inicializar ScreenUtil para diseño responsive
  await ScreenUtil.ensureScreenSize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inicializar deep links al construir la app
    DeepLinkService().init();
    return MultiProvider(
      providers: [
        BlocProvider<SplashBloc>(
          create: (context) => SplashBloc(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider<NavigationProvider>(
          create: (context) => NavigationProvider(),
        ),
        ChangeNotifierProvider<MediaPlaybackProvider>(
          create: (context) => MediaPlaybackProvider(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // Tamaño de diseño base (iPhone X)
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'Memoria Viva Nicaragua',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light, // Forzamos tema claro para consistencia
            debugShowCheckedModeBanner: false,
            // Registramos el observador de rutas para controlar las animaciones
            navigatorObservers: [LoginScreen.routeObserver],
            navigatorKey: AppRouter.navigatorKey,
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppRoutes.splash,
          );
        },
      ),
    );
  }
}