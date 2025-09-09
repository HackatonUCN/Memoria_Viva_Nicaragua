import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';
import 'package:memoria_viva_nicaragua/domain/failures/failures.dart';
import 'package:memoria_viva_nicaragua/domain/factories/usecases.dart';

class RelatosProvider extends ChangeNotifier {
  final _relatoUseCases = UseCases.resolve().relatos;

  bool isLoading = false;
  String? error;
  List<Relato> items = [];

  StreamSubscription<List<Relato>>? _subscription;

  Future<void> init() async {
    // Carga inicial
    isLoading = true;
    error = null;
    notifyListeners();

    final initial = await _relatoUseCases.obtener.execute();
    initial.when(
      success: (data) {
        items = data;
      },
      failure: (f) {
        error = f.message;
      },
    );

    isLoading = false;
    notifyListeners();

    // Suscribirse a cambios en tiempo real
    _subscription?.cancel();
    _subscription = _relatoUseCases.obtener.observe().listen(
      (data) {
        items = data;
        notifyListeners();
      },
      onError: (e) {
        error = e is Failure ? e.message : e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    error = null;
    final result = await _relatoUseCases.obtener.execute();
    result.when(
      success: (data) => items = data,
      failure: (f) => error = f.message,
    );
    notifyListeners();
  }

  Future<void> like(String relatoId) async {
    // Obsoleto: este provider no se usa en Feed. Mantener placeholder.
  }

  Future<void> share(String relatoId) async {
    // Optimistic update
    final idx = items.indexWhere((r) => r.id == relatoId);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(compartidos: items[idx].compartidos + 1);
      notifyListeners();
    }
    final result = await _relatoUseCases.compartir.execute(relatoId: relatoId);
    if (result.isFailure) {
      if (idx != -1) {
        items[idx] = items[idx].copyWith(compartidos: (items[idx].compartidos - 1).clamp(0, 1 << 30));
        notifyListeners();
      }
      error = result.errorOrNull?.message;
    }
  }

  Future<void> report({required String usuarioId, required String relatoId, required String razon}) async {
    final result = await _relatoUseCases.reportar.execute(
      usuarioId: usuarioId,
      relatoId: relatoId,
      razon: razon,
    );
    if (result.isFailure) {
      error = result.errorOrNull?.message;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}


