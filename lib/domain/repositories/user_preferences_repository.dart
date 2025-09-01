import '../entities/user_preferences.dart';

/// Repositorio para manejar las preferencias de usuario
abstract class IUserPreferencesRepository {
  /// Obtiene las preferencias de un usuario
  Future<UserPreferences> obtenerPreferencias(String userId);

  /// Guarda las preferencias de un usuario
  Future<void> guardarPreferencias(UserPreferences preferences);

  /// Agrega un relato a favoritos
  Future<void> agregarRelatoFavorito(String userId, String relatoId);

  /// Elimina un relato de favoritos
  Future<void> eliminarRelatoFavorito(String userId, String relatoId);

  /// Agrega una categoría a favoritos
  Future<void> agregarCategoriaFavorita(String userId, String categoriaId);

  /// Elimina una categoría de favoritos
  Future<void> eliminarCategoriaFavorita(String userId, String categoriaId);

  /// Agrega un saber a favoritos
  Future<void> agregarSaberFavorito(String userId, String saberId);

  /// Elimina un saber de favoritos
  Future<void> eliminarSaberFavorito(String userId, String saberId);

  /// Agrega un evento a favoritos
  Future<void> agregarEventoFavorito(String userId, String eventoId);

  /// Elimina un evento de favoritos
  Future<void> eliminarEventoFavorito(String userId, String eventoId);

  /// Actualiza el tema de la app
  Future<void> actualizarTema(String userId, bool isDarkMode);

  /// Actualiza el idioma
  Future<void> actualizarIdioma(String userId, String language);

  /// Actualiza las preferencias de notificaciones
  Future<void> actualizarNotificaciones(String userId, bool enabled);

  /// Actualiza las preferencias de privacidad
  Future<void> actualizarPrivacidad({
    required String userId,
    bool? perfilPublico,
    bool? mostrarUbicacion,
    bool? permitirComentarios,
  });

  /// Actualiza las preferencias de ubicación
  Future<void> actualizarPreferenciasUbicacion({
    required String userId,
    List<String>? departamentos,
    List<String>? municipios,
    double? radioNotificaciones,
  });

  /// Stream para observar cambios en las preferencias
  Stream<UserPreferences> observarPreferencias(String userId);
}
