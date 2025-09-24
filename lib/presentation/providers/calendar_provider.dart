import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../domain/factories/usecases.dart';

/// Provider: gestiona calendario, día seleccionado, formato y marcadores por día
class CalendarProvider extends ChangeNotifier {
  final _useCases = UseCases.resolve().eventos;

  CalendarFormat _format = CalendarFormat.month;
  CalendarFormat get format => _format;

  DateTime _selectedDay = DateTime.now();
  DateTime get selectedDay => _selectedDay;

  DateTime _focusedDay = DateTime.now();
  DateTime get focusedDay => _focusedDay;

  // Marcadores: fecha (solo día) -> cantidad
  Map<DateTime, int> markersByDay = const {};

  bool loading = false;
  String? error;

  Future<void> init() async {
    await _loadMarkers();
  }

  void setFormat(CalendarFormat f) {
    if (_format == f) return;
    _format = f;
    notifyListeners();
  }

  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
    _loadMarkers();
  }

  void setSelectedDay(DateTime day) {
    _selectedDay = DateTime(day.year, day.month, day.day);
    notifyListeners();
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, 1);
  DateTime _startOfNextMonth(DateTime d) => (d.month == 12)
      ? DateTime(d.year + 1, 1, 1)
      : DateTime(d.year, d.month + 1, 1);

  Future<void> _loadMarkers() async {
    loading = true;
    error = null;
    notifyListeners();
    final inicio = _startOfDay(_focusedDay);
    final fin = _startOfNextMonth(_focusedDay);
    final res = await _useCases.marcadoresPorMes.execute(inicio: inicio, fin: fin);
    res.when(
      success: (data) => markersByDay = data,
      failure: (f) => error = f.message,
    );
    loading = false;
    notifyListeners();
  }
}


