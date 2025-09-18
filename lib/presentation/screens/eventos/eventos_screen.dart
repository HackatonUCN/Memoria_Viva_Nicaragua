import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../utils/date_formatter.dart';
import '../../providers/eventos_provider.dart';
import '../../providers/event_carousel_provider.dart';
import '../../providers/event_list_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../widgets/eventos/evento_detail_overlay.dart';
import '../../widgets/eventos/evento_card.dart';
import '../../widgets/eventos/evento_square_card.dart';
import '../../widgets/eventos/event_category_chips.dart';
import '../../widgets/common/empty_view.dart';
import '../../widgets/common/error_view.dart';
import 'evento_form_sheet.dart';
import 'moderacion_sugerencias_screen.dart';

class EventosScreen extends StatelessWidget {
  const EventosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider original para admin/CRUD
        ChangeNotifierProvider(create: (_) => EventosProvider()..init()),
        // Nuevos providers segmentados
        ChangeNotifierProvider(create: (_) => CalendarProvider()..init()),
        ChangeNotifierProvider(create: (_) => EventCarouselProvider()..init()),
        ChangeNotifierProvider(create: (_) => EventListProvider()),
      ],
      child: const _EventosSliverContent(),
    );
  }
}

class _EventosSliverContent extends StatefulWidget {
  const _EventosSliverContent();

  @override
  State<_EventosSliverContent> createState() => _EventosSliverContentState();
}

class _EventosSliverContentState extends State<_EventosSliverContent> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _showScrollTop = false;
  String _searchQuery = '';
  _QuickRange? _activeQuickRange;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final bool show = _scrollCtrl.hasClients && _scrollCtrl.offset > 300;
      if (show != _showScrollTop && mounted) setState(() => _showScrollTop = show);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cal = context.read<CalendarProvider>();
      final list = context.read<EventListProvider>();
      list.init(initialRange: _computeVisibleRange(cal));
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onQuickSelect(_QuickRange range, CalendarProvider cal, EventListProvider list) {
    final now = DateTime.now();
    setState(() {
      _activeQuickRange = range;
      if (range == _QuickRange.hoy) {
        final d = DateTime(now.year, now.month, now.day);
        cal.setSelectedDay(d);
        cal.setFocusedDay(d);
      } else if (range == _QuickRange.manana) {
        final t = now.add(const Duration(days: 1));
        final d = DateTime(t.year, t.month, t.day);
        cal.setSelectedDay(d);
        cal.setFocusedDay(d);
      } else if (range == _QuickRange.semana) {
        cal.setFormat(CalendarFormat.week);
        cal.setFocusedDay(now);
      } else if (range == _QuickRange.mes) {
        cal.setFormat(CalendarFormat.month);
        cal.setFocusedDay(DateTime(now.year, now.month, 1));
      }
    });
    list.setVisibleRange(_computeVisibleRange(cal));
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endExclusiveOfDay(DateTime d) => _startOfDay(d).add(const Duration(days: 1));
  DateTime _startOfWeek(DateTime d) => _startOfDay(d).subtract(Duration(days: d.weekday - 1));
  DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  DateTime _startOfNextMonth(DateTime d) => (d.month == 12) ? DateTime(d.year + 1, 1, 1) : DateTime(d.year, d.month + 1, 1);

  DateTimeRange _computeVisibleRange(CalendarProvider cal) {
    if (_activeQuickRange == _QuickRange.hoy) {
      final s = _startOfDay(cal.selectedDay);
      return DateTimeRange(start: s, end: s.add(const Duration(days: 1)));
    }
    if (_activeQuickRange == _QuickRange.manana) {
      final s0 = _startOfDay(DateTime.now().add(const Duration(days: 1)));
      return DateTimeRange(start: s0, end: s0.add(const Duration(days: 1)));
    }
    if (cal.format == CalendarFormat.week) {
      final s = _startOfWeek(cal.focusedDay);
      return DateTimeRange(start: s, end: s.add(const Duration(days: 7)));
    }
    if (cal.format == CalendarFormat.twoWeeks) {
      final s = _startOfWeek(cal.focusedDay);
      return DateTimeRange(start: s, end: s.add(const Duration(days: 14)));
    }
    // Mes
    final m0 = _startOfMonth(cal.focusedDay);
    final m1 = _startOfNextMonth(cal.focusedDay);
    return DateTimeRange(start: m0, end: m1);
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _formatMonth(DateTime d) {
    final String mm = d.month.toString().padLeft(2, '0');
    return 'Mes $mm/${d.year}';
  }

  String _normalize(String input) {
    const Map<String, String> map = {
      'á': 'a','é': 'e','í': 'i','ó': 'o','ú': 'u','ü': 'u','ñ': 'n',
      'Á': 'a','É': 'e','Í': 'i','Ó': 'o','Ú': 'u','Ü': 'u','Ñ': 'n',
    };
    final buffer = StringBuffer();
    for (final ch in input.characters) {
      buffer.write(map[ch] ?? ch);
    }
    return buffer.toString().toLowerCase();
  }

  

  @override
  Widget build(BuildContext context) {
    final eventosAdmin = context.watch<EventosProvider>();
    final isAdmin = eventosAdmin.isAdmin;
    final cal = context.watch<CalendarProvider>();
    final carousel = context.watch<EventCarouselProvider>();
    final listProv = context.watch<EventListProvider>();
    final List headerEventos = carousel.eventsForCarousel;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              context.read<EventosProvider>().refresh(),
              context.read<EventCarouselProvider>().refresh(),
              context.read<EventListProvider>().refresh(),
            ]);
            final c = context.read<CalendarProvider>();
            c.setFocusedDay(c.focusedDay);
          },
          child: Stack(
            children: [
              CustomScrollView(
                controller: _scrollCtrl,
                slivers: [
                  // Header: título
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text('Eventos', style: AppTypography.textTheme.titleLarge?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Chips de categorías
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: EventCategoryChips(
                        selectedCategoryId: carousel.selectedCategoryId,
                        onChanged: (id) => context.read<EventCarouselProvider>().setSelectedCategory(id),
                      ),
                    ),
                  ),
                  // Carrusel horizontal de tarjetas cuadradas
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 160,
                      child: carousel.loading
                          ? ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemBuilder: (_, __) => Container(width: 140, height: 140, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16))),
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemCount: 6,
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemBuilder: (ctx, i) => EventoSquareCard(
                                evento: headerEventos[i],
                                onTap: () => EventoDetailOverlay.open(context, headerEventos[i]),
                              ),
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemCount: headerEventos.length,
                            ),
                    ),
                  ),
                  // Búsqueda + chips rápidos
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            onChanged: (v) {
                              setState(() => _searchQuery = v);
                              listProv.setSearchText(v);
                            },
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Buscar eventos por nombre, autor, municipio o departamento...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.inputBorder.withOpacity(0.5))),
                            child: _QuickFiltersRow(onSelect: (r) => _onQuickSelect(r, cal, listProv)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Calendario con selector de vista
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TableCalendar(
                          firstDay: DateTime.now().subtract(const Duration(days: 365)),
                          lastDay: DateTime.now().add(const Duration(days: 365)),
                          focusedDay: cal.focusedDay,
                          selectedDayPredicate: (d) => isSameDay(d, cal.selectedDay),
                          onDaySelected: (d, f) {
                            cal.setSelectedDay(d);
                            cal.setFocusedDay(f);
                            setState(() { _activeQuickRange = _QuickRange.hoy; });
                            listProv.setVisibleRange(_computeVisibleRange(cal));
                          },
                          onPageChanged: (f) {
                            cal.setFocusedDay(f);
                            setState(() { _activeQuickRange = null; });
                            listProv.setVisibleRange(_computeVisibleRange(cal));
                          },
                          onFormatChanged: (f) {
                            cal.setFormat(f);
                            setState(() { _activeQuickRange = null; });
                            listProv.setVisibleRange(_computeVisibleRange(cal));
                          },
                          calendarFormat: cal.format,
                          locale: 'es_ES',
                          eventLoader: (day) {
                            final key = DateTime(day.year, day.month, day.day);
                            final count = cal.markersByDay[key] ?? 0;
                            return List.generate(count, (_) => 1);
                          },
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, day, events) {
                              final int count = events.length;
                              if (count == 0) return const SizedBox.shrink();
                              final int dots = count == 1 ? 1 : 2;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(dots, (i) => Container(
                                      width: 6,
                                      height: 6,
                                      margin: EdgeInsets.only(top: 2, right: dots == 2 && i == 0 ? 2 : 0, left: dots == 2 && i == 1 ? 2 : 0),
                                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                                    )),
                              );
                            },
                          ),
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: true,
                            formatButtonShowsNext: false,
                            headerPadding: const EdgeInsets.symmetric(vertical: 8),
                            titleTextStyle: AppTypography.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                            leftChevronIcon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                              child: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                            ),
                            rightChevronIcon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                              child: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                            ),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: AppTypography.textTheme.bodySmall!.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            weekendStyle: AppTypography.textTheme.bodySmall!.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600),
                          ),
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            todayDecoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), border: Border.all(color: AppColors.primary, width: 2), shape: BoxShape.circle),
                            todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            selectedDecoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                            selectedTextStyle: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
                            weekendTextStyle: TextStyle(color: AppColors.accent.withOpacity(0.8), fontWeight: FontWeight.w500),
                            defaultTextStyle: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                            markerDecoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                            markersMaxCount: 3,
                            markerSize: 6,
                          ),
                          availableCalendarFormats: const {
                            CalendarFormat.week: 'Semana',
                            CalendarFormat.twoWeeks: 'Quincena',
                            CalendarFormat.month: 'Mes',
                          },
                        ),
                      ),
                    ),
                  ),
                  // Botones de acción (Sugerir/Publicar + Moderación)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final res = await EventoFormSheet.open(context, publicarDirecto: isAdmin);
                                if (res?.errorMessage != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.error, content: Text(res!.errorMessage!)));
                                } else if (res?.success == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.success, content: Text(isAdmin ? 'Evento publicado' : 'Sugerencia enviada')));
                                }
                              },
                              icon: Icon(isAdmin ? Icons.event_available_rounded : Icons.add_rounded),
                              label: Text(isAdmin ? 'Publicar' : 'Sugerir'),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Moderación',
                                icon: const Icon(Icons.verified_outlined, color: AppColors.primary),
                                onPressed: () {
                                  final prov = context.read<EventosProvider>();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChangeNotifierProvider.value(value: prov, child: const ModeracionSugerenciasScreen()),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Lista de eventos
                  if (listProv.loading)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Container(height: 220, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16))),
                        ),
                        childCount: 6,
                      ),
                    )
                  else if (listProv.error != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorView(message: listProv.error!, onRetry: listProv.refresh),
                    )
                  else if (listProv.eventsForList.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const EmptyView(message: 'No hay eventos para los filtros actuales'),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final res = await EventoFormSheet.open(context, publicarDirecto: isAdmin);
                              if (res?.success == true) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.success, content: Text(isAdmin ? 'Evento publicado' : 'Sugerencia enviada')));
                              }
                            },
                            icon: Icon(isAdmin ? Icons.event_available_rounded : Icons.add_rounded),
                            label: Text(isAdmin ? 'Publicar' : 'Sugerir'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final e = listProv.eventsForList[index];
                          return EventoCard(
                            evento: e,
                            onTap: () => EventoDetailOverlay.open(context, e),
                            isAdmin: isAdmin,
                            onEdit: isAdmin
                                ? () async {
                                    await EventoFormSheet.open(context, initial: e, publicarDirecto: true);
                                  }
                                : null,
                            onDelete: isAdmin
                                ? () async {
                                    final err = await context.read<EventosProvider>().eliminarEvento(e.id);
                                    if (err != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.error, content: Text(err)));
                                    }
                                  }
                                : null,
                          );
                        },
                        childCount: listProv.eventsForList.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Resultados: ${listProv.eventsForList.length}', style: AppTypography.textTheme.labelMedium),
                            const SizedBox(height: 4),
                            Builder(
                              builder: (ctx) {
                                final range = _computeVisibleRange(cal);
                                final String rangoLabel = () {
                                  if (_activeQuickRange == _QuickRange.hoy) {
                                    return 'Fecha: Hoy (${_formatDate(range.start)})';
                                  }
                                  if (_activeQuickRange == _QuickRange.manana) {
                                    return 'Fecha: Mañana (${_formatDate(range.start)})';
                                  }
                                  if (cal.format == CalendarFormat.week) {
                                    return 'Rango: Semana ${_formatDate(range.start)} - ${_formatDate(range.end.subtract(const Duration(days: 1)))}';
                                  }
                                  if (cal.format == CalendarFormat.twoWeeks) {
                                    return 'Rango: Quincena ${_formatDate(range.start)} - ${_formatDate(range.end.subtract(const Duration(days: 1)))}';
                                  }
                                  return 'Rango: ${_formatMonth(range.start)}';
                                }();
                                return Text(rangoLabel, style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // Botón flotante Ir al inicio
              Positioned(
                right: 16,
                bottom: 16,
                child: AnimatedScale(
                  scale: _showScrollTop ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: FloatingActionButton(
                    heroTag: "eventos_scroll_top",
                    mini: true,
                    tooltip: 'Ir al inicio',
                    onPressed: () => _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOut),
                    child: const Icon(Icons.vertical_align_top),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaList extends StatelessWidget {
  final List eventos;
  final VoidCallback? onDebugTap;
  const _AgendaList({required this.eventos, this.onDebugTap});

  @override
  Widget build(BuildContext context) {
    if (eventos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_busy_rounded,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay eventos',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No se encontraron eventos para esta fecha',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: eventos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final e = eventos[i];
        final fechaFormateada = DateFormatter.formatEventDateRange(e.fechaInicio, e.fechaFin);
        return _AgendaCard(
          eventoId: e.id,
          title: e.titulo,
          subtitle: '${e.ubicacion.municipio}, ${e.ubicacion.departamento}',
          time: fechaFormateada,
          organizador: e.organizador,
          onTap: () {
            onDebugTap?.call();
            EventoDetailOverlay.open(context, e);
          },
          menuBuilder: context.read<EventosProvider>().isAdmin
              ? (ctx) => [
                    PopupMenuItem(value: 'edit', child: const Text('Editar'), onTap: () async {
                      await Future<void>.delayed(const Duration(milliseconds: 10));
                      await EventoFormSheet.open(ctx, initial: e, publicarDirecto: true);
                    }),
                    PopupMenuItem(value: 'delete', child: const Text('Eliminar'), onTap: () async {
                      await Future<void>.delayed(const Duration(milliseconds: 10));
                      final err = await ctx.read<EventosProvider>().eliminarEvento(e.id);
                      if (err != null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(backgroundColor: AppColors.error, content: Text(err)));
                      }
                    }),
                  ]
              : null,
        );
      },
    );
  }
}


enum _QuickRange { hoy, manana, semana, mes }

class _QuickFiltersRow extends StatelessWidget {
  final void Function(_QuickRange range) onSelect;
  const _QuickFiltersRow({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, _QuickRange r, {IconData? icon, Color? color}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: OutlinedButton.icon(
          onPressed: () => onSelect(r),
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.background,
            foregroundColor: color ?? AppColors.primary,
            side: BorderSide(color: (color ?? AppColors.primary).withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color ?? AppColors.primary,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          chip('Hoy', _QuickRange.hoy, icon: Icons.today_rounded, color: AppColors.accent),
          chip('Mañana', _QuickRange.manana, icon: Icons.calendar_view_day_rounded),
          chip('Semana', _QuickRange.semana, icon: Icons.view_week_rounded),
          chip('Mes', _QuickRange.mes, icon: Icons.calendar_month_rounded),
        ],
      ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  final String eventoId;
  final String title;
  final String subtitle;
  final String time;
  final String organizador;
  final VoidCallback onTap;
  final List<PopupMenuEntry<String>> Function(BuildContext context)? menuBuilder;

  const _AgendaCard({
    required this.eventoId,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.organizador,
    required this.onTap,
    this.menuBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final eventosProvider = context.watch<EventosProvider>();
    final isUpdating = eventosProvider.isEventUpdating(eventoId);
    final isDeleting = eventosProvider.isEventDeleting(eventoId);
    final isLoading = isUpdating || isDeleting;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.schedule, size: 16, color: AppColors.textLight),
                  const SizedBox(height: 4),
                  Text(time, style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.textLight) ?? const TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryDark, 
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          subtitle, 
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          organizador,
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event_available_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('Ver detalles', style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            if (menuBuilder != null) ...[
              PopupMenuButton<String>(
                itemBuilder: (ctx) => menuBuilder!(ctx),
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              ),
            ],
            ],
            ),
            // Loading overlay
            if (isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isUpdating ? 'Actualizando...' : 'Eliminando...',
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


