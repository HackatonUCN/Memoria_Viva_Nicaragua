import '../enums/estado_moderacion.dart';
import '../enums/roles_usuario.dart';
import '../entities/user.dart';
import '../entities/relato.dart';
import '../entities/saber_popular.dart';
import '../entities/evento_cultural.dart';

/// Política de moderación para el contenido de la aplicación
/// 
/// Define las reglas de negocio para la moderación de contenido,
/// incluyendo quién puede moderar, qué contenido requiere moderación,
/// y las reglas para aprobar o rechazar contenido.
class ModeracionPolicy {
  /// Número de reportes que activan revisión automática
  static const int UMBRAL_REPORTES = 3;
  
  /// Palabras prohibidas en el contenido
  static final List<String> PALABRAS_PROHIBIDAS = [
    'palabrota1',
    'palabrota2',
    // Agregar palabras prohibidas según necesidad
  ];

  /// Verifica si un usuario puede moderar contenido
  static bool puedeModerar(User usuario) {
    return usuario.rol == UserRole.admin;
  }

  /// Verifica si un usuario puede moderar un relato específico
  static bool puedeModararRelato(User usuario, Relato relato) {
    // Un usuario no puede moderar su propio contenido
    if (relato.autorId == usuario.id) {
      return false;
    }
    
    return puedeModerar(usuario);
  }

  /// Verifica si un usuario puede moderar un saber popular específico
  static bool puedeModararSaber(User usuario, SaberPopular saber) {
    // Un usuario no puede moderar su propio contenido
    if (saber.autorId == usuario.id) {
      return false;
    }
    
    return puedeModerar(usuario);
  }

  /// Verifica si un usuario puede moderar un evento cultural específico
  static bool puedeModararEvento(User usuario, EventoCultural evento) {
    // Un usuario no puede moderar su propio contenido
    if (evento.creadoPorId == usuario.id) {
      return false;
    }
    
    return puedeModerar(usuario);
  }

  /// Verifica si un contenido necesita revisión automática
  static bool requiereRevisionAutomatica(int reportes) {
    return reportes >= UMBRAL_REPORTES;
  }

  /// Verifica si un texto contiene palabras prohibidas
  static bool contienePalabrasProhibidas(String texto) {
    final textoNormalizado = texto.toLowerCase();
    return PALABRAS_PROHIBIDAS.any(
      (palabra) => textoNormalizado.contains(palabra.toLowerCase())
    );
  }

  /// Verifica si un relato contiene contenido prohibido
  static bool relatoContienePalabrasProhibidas(Relato relato) {
    return contienePalabrasProhibidas(relato.titulo) ||
           contienePalabrasProhibidas(relato.contenido);
  }

  /// Verifica si un saber popular contiene contenido prohibido
  static bool saberContienePalabrasProhibidas(SaberPopular saber) {
    return contienePalabrasProhibidas(saber.titulo) ||
           contienePalabrasProhibidas(saber.contenido);
  }

  /// Verifica si un evento cultural contiene contenido prohibido
  static bool eventoContienePalabrasProhibidas(EventoCultural evento) {
    return contienePalabrasProhibidas(evento.nombre) ||
           contienePalabrasProhibidas(evento.descripcion);
  }

  /// Determina el estado de moderación inicial para un nuevo contenido
  /// basado en el rol del usuario y el contenido
  static EstadoModeracion estadoInicialContenido(User autor, String texto) {
    // Los administradores no requieren aprobación previa
    if (autor.rol == UserRole.admin) {
      return EstadoModeracion.activo;
    }
    
    // Si contiene palabras prohibidas, se marca como pendiente
    if (contienePalabrasProhibidas(texto)) {
      return EstadoModeracion.pendiente;
    }

    // Por defecto, el contenido es activo
    return EstadoModeracion.activo;
  }

  /// Verifica si un usuario puede reportar contenido
  static bool puedeReportar(User usuario) {
    // Solo usuarios registrados pueden reportar
    return usuario.id.isNotEmpty;
  }

  /// Verifica si un usuario puede reportar un contenido específico
  static bool puedeReportarContenido(User usuario, String autorId) {
    // Un usuario no puede reportar su propio contenido
    return usuario.id != autorId && puedeReportar(usuario);
  }

  /// Obtiene la razón por la que un contenido fue rechazado automáticamente
  static String? razonRechazoAutomatico(String texto) {
    if (contienePalabrasProhibidas(texto)) {
      return 'El contenido contiene palabras prohibidas';
    }
    return null;
  }
}
