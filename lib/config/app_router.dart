import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/placeholders/chatbot_screen.dart' as placeholders;

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String mapa = '/mapa';
  static const String publicar = '/publicar';
  static const String eventos = '/eventos';
  static const String biblioteca = '/biblioteca';
  static const String chatbot = '/chatbot';
  static const String perfil = '/perfil';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _material(
          SplashScreen(
            onComplete: () {
              // Decidir a dónde ir según estado de auth
              final navigator = _navigatorKey.currentState;
              final context = navigator?.context;
              if (context != null) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                if (auth.status == AuthStatus.authenticated) {
                  navigator?.pushReplacementNamed(AppRoutes.home);
                } else {
                  navigator?.pushReplacementNamed(AppRoutes.login);
                }
              }
            },
          ),
          settings,
        );

      case AppRoutes.login:
        return _material(
          _RedirectIfAuthenticated(child: const LoginScreen(), redirectTo: AppRoutes.home),
          settings,
        );

      case AppRoutes.register:
        return _material(const RegisterScreen(), settings);

      case AppRoutes.home:
        // Permite recibir argumento opcional {'relatoId': id} desde deep link
        final args = settings.arguments;
        return _material(
          _AuthRequired(child: const HomeScreen(title: '', initialIndex: 0)),
          settings,
        );
      case AppRoutes.mapa:
        return _material(
          _AuthRequired(child: const HomeScreen(title: '', initialIndex: 1)),
          settings,
        );
      case AppRoutes.publicar:
        return _material(
          _AuthRequired(child: const HomeScreen(title: '', initialIndex: 2)),
          settings,
        );
      case AppRoutes.eventos:
        return _material(
          _AuthRequired(child: const HomeScreen(title: '', initialIndex: 3)),
          settings,
        );
      case AppRoutes.biblioteca:
        return _material(
          _AuthRequired(child: const HomeScreen(title: '', initialIndex: 4)),
          settings,
        );
      case AppRoutes.chatbot:
        return _material(
          _AuthRequired(child: const placeholders.ChatbotScreen()),
          settings,
        );

      default:
        return _material(
          const _UnknownRouteScreen(),
          settings,
        );
    }
  }

  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  static MaterialPageRoute _material(Widget child, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => child, settings: settings);
  }
}

class _AuthRequired extends StatelessWidget {
  final Widget child;
  const _AuthRequired({required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.status == AuthStatus.authenticated) {
      return child;
    }

    // Mientras se resuelve el estado inicial o autenticación en curso, mostrar loading
    if (auth.status == AuthStatus.initial || auth.status == AuthStatus.authenticating) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // No autenticado: redirigir a login sin bloquear el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      } else {
        Navigator.of(context).pushNamed(AppRoutes.login);
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _RedirectIfAuthenticated extends StatelessWidget {
  final Widget child;
  final String redirectTo;
  const _RedirectIfAuthenticated({required this.child, required this.redirectTo});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(redirectTo);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return child;
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página no encontrada')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('La ruta solicitada no existe.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}


