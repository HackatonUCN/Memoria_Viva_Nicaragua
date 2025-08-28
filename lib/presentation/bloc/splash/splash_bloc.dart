import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(const SplashState()) {
    on<SplashStarted>(_onSplashStarted);
    on<SplashAnimationCompleted>(_onAnimationCompleted);
    on<SplashDataLoaded>(_onDataLoaded);
    on<SplashError>(_onError);

    // Iniciar automáticamente el splash
    add(const SplashStarted());

    // Simular carga de datos (puedes reemplazar esto con carga real)
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (!isClosed) {  // Verificar que el bloc no esté cerrado
        add(const SplashDataLoaded());
      }
    });
  }

  void _onSplashStarted(SplashStarted event, Emitter<SplashState> emit) {
    if (kDebugMode) {
      print('Splash iniciado');
    }
    emit(state.copyWith(
      status: SplashStatus.loading,
      isAnimationCompleted: false,
      isDataLoaded: false,
    ));
  }

  void _onAnimationCompleted(SplashAnimationCompleted event, Emitter<SplashState> emit) {
    if (kDebugMode) {
      print('Animación completada');
    }
    final newState = state.copyWith(
      isAnimationCompleted: true,
    );

    emit(
      newState.copyWith(
        status: _shouldComplete(newState) ? SplashStatus.completed : SplashStatus.loading,
      ),
    );
  }

  void _onDataLoaded(SplashDataLoaded event, Emitter<SplashState> emit) {
    if (kDebugMode) {
      print('Datos cargados');
    }
    final newState = state.copyWith(
      isDataLoaded: true,
    );

    emit(
      newState.copyWith(
        status: _shouldComplete(newState) ? SplashStatus.completed : SplashStatus.loading,
      ),
    );
  }

  void _onError(SplashError event, Emitter<SplashState> emit) {
    emit(state.copyWith(
      status: SplashStatus.error,
      error: event.message,
    ));
  }

  bool _shouldComplete(SplashState state) {
    return state.isAnimationCompleted && state.isDataLoaded;
  }

  @override
  Future<void> close() {
    // Limpieza adicional si es necesaria
    return super.close();
  }
}