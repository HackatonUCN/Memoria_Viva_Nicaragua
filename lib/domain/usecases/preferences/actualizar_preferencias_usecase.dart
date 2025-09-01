import '../../entities/user_preferences.dart';
import '../../repositories/user_preferences_repository.dart';

/// Caso de uso para actualizar las preferencias del usuario
class ActualizarPreferenciasUseCase {
  final IUserPreferencesRepository _preferencesRepository;

  ActualizarPreferenciasUseCase(this._preferencesRepository);

  /// Actualiza las preferencias del usuario
  Future<void> execute({
    required String userId,
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
    bool? perfilPublico,
    bool? mostrarUbicacion,
    bool? permitirComentarios,
    List<String>? departamentosInteres,
    List<String>? municipiosInteres,
    double? radioNotificaciones,
  }) async {
    try {
      // Obtener preferencias actuales
      final preferencias = await _preferencesRepository.obtenerPreferencias(userId);

      // Actualizar con nuevos valores
      final nuevasPreferencias = preferencias.copyWith(
        isDarkMode: isDarkMode,
        language: language,
        notificationsEnabled: notificationsEnabled,
        perfilPublico: perfilPublico,
        mostrarUbicacion: mostrarUbicacion,
        permitirComentarios: permitirComentarios,
        departamentosInteres: departamentosInteres,
        municipiosInteres: municipiosInteres,
        radioNotificaciones: radioNotificaciones,
      );

      // Guardar cambios
      await _preferencesRepository.guardarPreferencias(nuevasPreferencias);
    } catch (e) {
      throw Exception('Error al actualizar preferencias: $e');
    }
  }
}
