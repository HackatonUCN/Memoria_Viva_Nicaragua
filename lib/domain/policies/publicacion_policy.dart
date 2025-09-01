import '../entities/user.dart';
import '../entities/relato.dart';
import '../entities/saber_popular.dart';
import '../entities/evento_cultural.dart';
import '../value_objects/ubicacion.dart';
import '../policies/permisos_policy.dart';

/// Política para validar publicación de contenido (pre-condiciones)
class PublicacionPolicy {
  static const int MIN_TITULO = 3;
  static const int MIN_CONTENIDO = 10;

  static bool puedePublicarRelato({required User autor, required Relato relato}) {
    if (!PermisosPolicy.puedeCrearRelato(autor)) return false;
    if (relato.titulo.trim().length < MIN_TITULO) return false;
    if (relato.contenido.trim().length < MIN_CONTENIDO) return false;
    return true;
  }

  static bool puedePublicarSaber({required User autor, required SaberPopular saber}) {
    if (!PermisosPolicy.puedeCrearSaber(autor)) return false;
    if (saber.titulo.trim().length < MIN_TITULO) return false;
    if (saber.contenido.trim().length < MIN_CONTENIDO) return false;
    return true;
  }

  static bool puedePublicarEvento({required User autor, required EventoCultural evento}) {
    if (!PermisosPolicy.puedeCrearEvento(autor)) return false;
    // Validaciones mínimas de ejemplo; fechas y ubicación se validan en entidades/validators
    if (evento.titulo.trim().length < MIN_TITULO) return false;
    if (evento.descripcion.trim().length < MIN_CONTENIDO) return false;
    return true;
  }

  static bool ubicacionValidaNicaragua(Ubicacion ubicacion) {
    return ubicacion.latitud >= Ubicacion.MIN_LAT_NICARAGUA &&
           ubicacion.latitud <= Ubicacion.MAX_LAT_NICARAGUA &&
           ubicacion.longitud >= Ubicacion.MIN_LON_NICARAGUA &&
           ubicacion.longitud <= Ubicacion.MAX_LON_NICARAGUA;
  }
}
