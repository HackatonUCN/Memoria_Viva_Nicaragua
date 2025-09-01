import '../../repositories/user_preferences_repository.dart';

/// Tipo de contenido que puede ser favorito
enum TipoFavorito {
  relato,
  saber,
  evento,
  categoria,
}

/// Caso de uso para agregar/quitar favoritos
class ToggleFavoritoUseCase {
  final IUserPreferencesRepository _preferencesRepository;

  ToggleFavoritoUseCase(this._preferencesRepository);

  /// Agrega o quita un elemento de favoritos
  /// 
  /// [userId] - ID del usuario
  /// [itemId] - ID del elemento a marcar/desmarcar
  /// [tipo] - Tipo de contenido
  /// [agregar] - true para agregar, false para quitar
  Future<void> execute({
    required String userId,
    required String itemId,
    required TipoFavorito tipo,
    required bool agregar,
  }) async {
    try {
      switch (tipo) {
        case TipoFavorito.relato:
          if (agregar) {
            await _preferencesRepository.agregarRelatoFavorito(userId, itemId);
          } else {
            await _preferencesRepository.eliminarRelatoFavorito(userId, itemId);
          }
          break;

        case TipoFavorito.saber:
          if (agregar) {
            await _preferencesRepository.agregarSaberFavorito(userId, itemId);
          } else {
            await _preferencesRepository.eliminarSaberFavorito(userId, itemId);
          }
          break;

        case TipoFavorito.evento:
          if (agregar) {
            await _preferencesRepository.agregarEventoFavorito(userId, itemId);
          } else {
            await _preferencesRepository.eliminarEventoFavorito(userId, itemId);
          }
          break;

        case TipoFavorito.categoria:
          if (agregar) {
            await _preferencesRepository.agregarCategoriaFavorita(userId, itemId);
          } else {
            await _preferencesRepository.eliminarCategoriaFavorita(userId, itemId);
          }
          break;
      }
    } catch (e) {
      throw Exception('Error al actualizar favorito: $e');
    }
  }
}
