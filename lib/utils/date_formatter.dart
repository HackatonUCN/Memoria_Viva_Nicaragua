
class DateFormatter {
  static final List<String> _diasSemana = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];
  
  static final List<String> _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  /// Formatea un rango de fechas de eventos de manera legible
  /// Ejemplos:
  /// - "Lunes 15 de Enero" (mismo día)
  /// - "Lunes 15 - Martes 16 de Enero" (días consecutivos mismo mes)
  /// - "Lunes 15 de Enero - Martes 16 de Febrero" (meses diferentes)
  static String formatEventDateRange(DateTime inicio, DateTime fin) {
    final bool mismoDia = inicio.year == fin.year && 
                          inicio.month == fin.month && 
                          inicio.day == fin.day;
    
    final bool mismoMes = inicio.year == fin.year && inicio.month == fin.month;
    final bool mismoAno = inicio.year == fin.year;

    if (mismoDia) {
      // Mismo día: "Lunes 15 de Enero"
      return _formatSingleDate(inicio);
    } else if (mismoMes) {
      // Mismo mes: "Lunes 15 - Martes 16 de Enero"
      final diaInicio = _diasSemana[inicio.weekday - 1];
      final diaFin = _diasSemana[fin.weekday - 1];
      final mes = _meses[inicio.month - 1];
      return '$diaInicio ${inicio.day} - $diaFin ${fin.day} de $mes';
    } else if (mismoAno) {
      // Mismo año, meses diferentes: "Lunes 15 de Enero - Martes 16 de Febrero"
      final fechaInicio = _formatSingleDate(inicio);
      final fechaFin = _formatSingleDate(fin);
      return '$fechaInicio - $fechaFin';
    } else {
      // Años diferentes: "Lunes 15 de Enero 2024 - Martes 16 de Febrero 2025"
      final fechaInicio = _formatSingleDateWithYear(inicio);
      final fechaFin = _formatSingleDateWithYear(fin);
      return '$fechaInicio - $fechaFin';
    }
  }

  /// Formatea una fecha individual: "Lunes 15 de Enero"
  static String _formatSingleDate(DateTime fecha) {
    final dia = _diasSemana[fecha.weekday - 1];
    final mes = _meses[fecha.month - 1];
    return '$dia ${fecha.day} de $mes';
  }

  /// Formatea una fecha individual con año: "Lunes 15 de Enero 2024"
  static String _formatSingleDateWithYear(DateTime fecha) {
    final dia = _diasSemana[fecha.weekday - 1];
    final mes = _meses[fecha.month - 1];
    return '$dia ${fecha.day} de $mes ${fecha.year}';
  }

  /// Formatea solo la fecha para uso compacto: "15 de Enero"
  static String formatCompactDate(DateTime fecha) {
    final mes = _meses[fecha.month - 1];
    return '${fecha.day} de $mes';
  }

  /// Formatea hora en formato 24h: "14:30"
  static String formatTime(DateTime fecha) {
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  /// Formatea fecha y hora para detalles: "Lunes 15 de Enero • 14:30 - 16:00"
  static String formatEventDateTimeRange(DateTime inicio, DateTime fin) {
    final bool mismoDia = inicio.year == fin.year && 
                          inicio.month == fin.month && 
                          inicio.day == fin.day;
    
    if (mismoDia) {
      final fecha = _formatSingleDate(inicio);
      final horaInicio = formatTime(inicio);
      final horaFin = formatTime(fin);
      return '$fecha • $horaInicio - $horaFin';
    } else {
      // Para eventos de múltiples días, solo mostrar el rango de fechas
      return formatEventDateRange(inicio, fin);
    }
  }
}
