import 'package:equatable/equatable.dart';

enum SplashStatus {
  initial,
  loading,
  animating,
  completed,
  error,
}

class SplashState extends Equatable {
  final SplashStatus status;
  final String? error;
  final bool isAnimationCompleted;
  final bool isDataLoaded;

  const SplashState({
    this.status = SplashStatus.initial,
    this.error,
    this.isAnimationCompleted = false,
    this.isDataLoaded = false,
  });

  SplashState copyWith({
    SplashStatus? status,
    String? error,
    bool? isAnimationCompleted,
    bool? isDataLoaded,
  }) {
    return SplashState(
      status: status ?? this.status,
      error: error ?? this.error,
      isAnimationCompleted: isAnimationCompleted ?? this.isAnimationCompleted,
      isDataLoaded: isDataLoaded ?? this.isDataLoaded,
    );
  }

  @override
  List<Object?> get props => [status, error, isAnimationCompleted, isDataLoaded];
}
