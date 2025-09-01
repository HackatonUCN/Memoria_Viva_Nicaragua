import 'dart:collection';

/// Política simple de rate limiting por usuario (memoria de proceso)
/// Nota: La implementación real debe vivir en infraestructura/servicios persistentes.
class RateLimitPolicy {
  static const int MAX_ACCIONES_MINUTO = 20;
  static const Duration VENTANA = Duration(minutes: 1);

  static final Map<String, Queue<DateTime>> _accionesPorUsuario = {};

  /// Registra una acción y devuelve si está permitida bajo el límite
  static bool registrarYPermitir(String userId) {
    final ahora = DateTime.now().toUtc();
    final cola = _accionesPorUsuario.putIfAbsent(userId, () => Queue<DateTime>());

    // Limpia acciones fuera de ventana
    while (cola.isNotEmpty && ahora.difference(cola.first) > VENTANA) {
      cola.removeFirst();
    }

    if (cola.length >= MAX_ACCIONES_MINUTO) {
      return false;
    }

    cola.addLast(ahora);
    return true;
  }

  /// Lee cuántas acciones hay en la ventana actual
  static int accionesEnVentana(String userId) {
    final ahora = DateTime.now().toUtc();
    final cola = _accionesPorUsuario[userId];
    if (cola == null) return 0;
    return cola.where((t) => ahora.difference(t) <= VENTANA).length;
  }
}
