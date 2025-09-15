import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:provider/provider.dart';

import '../../providers/feed_provider.dart';
import '../../widgets/feed/stories_strip.dart';
import '../../widgets/feed/filter_segmented_chips.dart';
import '../../widgets/relatos/relato_card.dart';
import '../../widgets/relatos/relato_detail_overlay.dart';
import '../../widgets/common/empty_view.dart';
import '../../widgets/common/error_view.dart';
import '../../../core/theme/app_typography.dart';
import '../auth/login_screen.dart';
import 'publicar_relato_sheet.dart';
import '../../providers/feed_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/relato.dart';
import '../../../domain/factories/usecases.dart';
import '../../providers/media_playback_provider.dart';
import '../../providers/navigation_provider.dart';
import 'package:share_plus/share_plus.dart';

class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});
  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _RelatosSkeletonSliver extends StatelessWidget {
  final int count;
  const _RelatosSkeletonSliver({this.count = 6});
  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SkeletonBox(height: 200, radius: BorderRadius.vertical(top: Radius.circular(16))),
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SkeletonLine(widthFactor: 0.8),
                          SizedBox(height: 10),
                          _SkeletonLine(widthFactor: 0.6),
                          SizedBox(height: 14),
                          _SkeletonLine(widthFactor: 1.0),
                          SizedBox(height: 6),
                          _SkeletonLine(widthFactor: 0.9),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
        childCount: count,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final BorderRadius? radius;
  const _SkeletonBox({required this.height, this.radius});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(12),
      child: Container(
        height: height,
        color: AppColors.withOpacity(AppColors.primary, 0.06),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double widthFactor;
  const _SkeletonLine({required this.widthFactor});
  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: _SkeletonBox(height: 14, radius: BorderRadius.circular(8)),
    );
  }
}

class _PlatformScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    // Sin efecto glow en móvil para menor sobrecosto visual
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // En web, scroll de escritorio; en móvil, física por defecto
    return kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics();
  }

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    if (kIsWeb) {
      return Scrollbar(thumbVisibility: true, controller: details.controller, child: child);
    }
    return child;
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Timer? _loadMoreDebounce;
  bool _loadMorePending = false;
  final ScrollController _scrollCtrl = ScrollController();
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    // Listener para mostrar/ocultar botón flotante de "ir arriba"
    _scrollCtrl.addListener(() {
      final bool show = _scrollCtrl.hasClients && _scrollCtrl.offset > 300;
      if (show != _showScrollTop && mounted) setState(() => _showScrollTop = show);
    });
  }

  void _showReportDialog(BuildContext context, String relatoId) async {
    final controller = TextEditingController();
    final provider = context.read<FeedProvider>();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reportar relato'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Describe el motivo (mín. 10 caracteres)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = controller.text.trim();
              if (reason.length < 10) return;
              await provider.reportRelato(relatoId: relatoId, razon: reason);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }

  void _showOwnerActions(BuildContext context, FeedProvider provider, Relato relato) async {
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                title: const Text('Editar'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final edited = await PublicarRelatoSheet.open(context, initialRelato: relato);
                  if (edited != null) {
                    provider.actualizarOptimista(edited);
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Eliminar'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dctx) => AlertDialog(
                      title: const Text('¿Eliminar este relato?'),
                      content: const Text('Esta acción no se puede deshacer.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancelar')),
                        ElevatedButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Eliminar')),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  final userId = provider.currentUserId;
                  if (userId == null) return;
                  messenger.showSnackBar(const SnackBar(content: Text('Eliminando…')));
                  final ok = await provider.eliminarOptimista(relatoId: relato.id, usuarioId: userId);
                  messenger.hideCurrentSnackBar();
                  if (ok) {
                    messenger.showSnackBar(const SnackBar(backgroundColor: AppColors.success, content: Text('Relato eliminado')));
                  } else {
                    messenger.showSnackBar(const SnackBar(backgroundColor: AppColors.error, content: Text('Error al eliminar. Se revirtió el cambio.')));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _onScrollNotification(ScrollNotification n, FeedProvider provider) {
    if (kIsWeb) return false; // en Web usamos botón
    if (n.metrics.maxScrollExtent <= 0) return false;
    final threshold = 600.0; // px antes del final
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - threshold) {
      if (!_loadMorePending && !provider.feedLoading && !provider.searching) {
        _loadMorePending = true;
        provider.loadMore();
        _loadMoreDebounce?.cancel();
        _loadMoreDebounce = Timer(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _loadMorePending = false);
        });
      }
    }
    return false;
  }

  @override
  void dispose() {
    _loadMoreDebounce?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FeedProvider()..init()),
      ],
      child: Consumer<FeedProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (n) => _onScrollNotification(n, provider),
                  child: ScrollConfiguration(
                    behavior: _PlatformScrollBehavior(),
                    child: CustomScrollView(
                      controller: _scrollCtrl,
                      cacheExtent: kIsWeb ? 1500 : 800,
                      slivers: [
                SliverToBoxAdapter(
                  child: StoriesStrip(
                    eventos: provider.historias,
                    loading: provider.storiesLoading,
                    error: provider.storiesError,
                    onSeeAll: () {},
                    onTap: (_) {},
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FeedSearchBar(),
                        const SizedBox(height: 8),
                        FilterSegmentedChips(
                          isLoggedIn: provider.isLoggedIn,
                          onLoginTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final creado = await PublicarRelatoSheet.open(context);
                          if (creado != null && context.mounted) {
                            final feed = context.read<FeedProvider>();
                            feed.insertarOptimista(creado);
                            // Si el filtro activo es "Mis relatos" y el autor coincide, permanecerá visible; caso contrario, el orden se encargará
                          }
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Publicar'),
                      ),
                    ),
                  ),
                ),
                if (provider.feedLoading || provider.searching || provider.filterSwitching)
                  _RelatosSkeletonSliver(count: kIsWeb ? 8 : 6)
                else if (provider.feedError != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(message: provider.feedError!, onRetry: provider.refresh),
                  )
                else if (provider.searchError != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(message: provider.searchError!, onRetry: () => provider.setSearchQuery(provider.searchQuery)),
                  )
                else if (provider.relatos.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyView(message: provider.searchQuery.isEmpty ? 'No hay relatos disponibles' : 'No hay resultados'),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final relato = provider.relatos[index];
                        final showMore = provider.filtro == FeedFilter.mis && provider.isLoggedIn && relato.autorId == provider.currentUserId;
                        final bool isOwner = provider.currentUserId != null && relato.autorId == provider.currentUserId;
                        return RepaintBoundary(
                          key: ValueKey(relato.id),
                          child: _KeepAlive(
                            child: Selector<FeedProvider, bool>(
                              selector: (ctx, p) => p.isLiked(relato.id),
                              builder: (ctx, isLiked, __) {
                                return RelatoCard(
                                  relato: relato,
                                  onTap: () => RelatoDetailOverlay.open(context, relato),
                                  onLike: isOwner ? null : () async { await provider.toggleLike(relato.id); },
                                  onShare: () async {
                                    final webUrl = Uri.parse('https://memoriaviva.app/relatos/${relato.id}');
                                    final message = '${relato.titulo}\n\n${relato.contenido.substring(0, relato.contenido.length > 120 ? 120 : relato.contenido.length)}…\n\nEnlace: $webUrl';
                                    await Share.share(message, subject: 'Relato – ${relato.titulo}');
                                    await provider.compartir(relato.id);
                                  },
                                  onReport: () => _showReportDialog(context, relato.id),
                                  showMore: showMore,
                                  onMore: showMore ? () => _showOwnerActions(context, provider, relato) : null,
                                  isLiked: isLiked,
                                );
                              },
                            ),
                          ),
                        );
                      },
                      childCount: provider.relatos.length,
                      addAutomaticKeepAlives: true,
                      addRepaintBoundaries: true,
                      addSemanticIndexes: false,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Resultados: ${provider.relatos.length}',
                        style: AppTypography.textTheme.labelMedium,
                      ),
                    ),
                  ),
                ),
                // Controles de paginación incremental
                if (kIsWeb)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      child: Align(
                        alignment: Alignment.center,
                        child: ElevatedButton.icon(
                          onPressed: () => provider.loadMore(),
                          icon: const Icon(Icons.expand_more),
                          label: const Text('Cargar más'),
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AnimatedOpacity(
                        opacity: _loadMorePending ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Center(child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                        )),
                      ),
                    ),
                  ),
                      ],
                    ),
                  ),
                ),
                // Botón flotante para ir al inicio
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: AnimatedScale(
                    scale: _showScrollTop ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: FloatingActionButton(
                      mini: true,
                      tooltip: 'Ir al inicio',
                      onPressed: () => _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOut),
                      child: const Icon(Icons.vertical_align_top),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FeedSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();


    return TextField(
      onChanged: provider.setSearchQuery,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Buscar relatos por título, autor, categoría o etiquetas...',
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        isDense: true,
      ),
    );
  }
}


