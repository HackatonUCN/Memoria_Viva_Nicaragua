import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/splash/splash_bloc.dart';
import '../../bloc/splash/splash_event.dart';
import '../../bloc/splash/splash_state.dart';
import '../../widgets/splash/animated_logo.dart';
import '../../widgets/splash/cultural_background.dart';
import '../../../core/theme/app_typography.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listenWhen: (previous, current) => 
        previous.status != current.status && current.status == SplashStatus.completed,
      listener: (context, state) {
        if (mounted && state.status == SplashStatus.completed) {
          widget.onComplete();
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo animado con elementos culturales
            const CulturalBackground(),

            // Contenido central
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo animado
                  AnimatedLogo(
                    onAnimationComplete: () {
                      context.read<SplashBloc>().add(
                        const SplashAnimationCompleted(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Título de la aplicación
                  Text(
                    'Memoria Viva',
                    style: AppTypography.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtítulo
                  Text(
                    'Nicaragua',
                    style: AppTypography.textTheme.headlineMedium,
                  ),
                ],
              ),
            ),

            // Indicador de carga en la parte inferior
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: BlocBuilder<SplashBloc, SplashState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      if (state.status == SplashStatus.loading)
                        const CircularProgressIndicator(),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            state.error!,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}