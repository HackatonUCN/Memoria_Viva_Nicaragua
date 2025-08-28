import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:memoria_viva_nicaragua/presentation/screens/auth/login_screen.dart';
import 'data/infrastructure/services/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash/splash_screen.dart';
// import 'presentation/screens/home/home_screen.dart'; // No se usa actualmente
import 'presentation/bloc/splash/splash_bloc.dart';
import 'presentation/providers/auth_provider.dart';
// Importamos RouteObserver para las animaciones

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializar Firebase solo si está disponible
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print('Firebase initialized successfully');
    }
  } catch (error) {
    if (kDebugMode) {
      print('Firebase initialization failed: $error');
      print('Continuing without Firebase...');
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
    return MultiProvider(
      providers: [
        BlocProvider<SplashBloc>(
          create: (context) => SplashBloc(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(),
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

            home: Builder(
              builder: (context) => SplashScreen(
                onComplete: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}