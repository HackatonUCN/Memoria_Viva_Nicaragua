import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/saberes/saberes_feed_provider.dart';
import '../../widgets/saberes/saber_card.dart';
import '../../widgets/saberes/saber_square_card.dart';
import '../../widgets/saberes/saber_detail_overlay.dart';
import '../../widgets/feed/filter_segmented_chips_saberes.dart';
import 'publicar_saber_popular_sheet.dart';
import 'package:share_plus/share_plus.dart';

class SaberesFeedScreen extends StatefulWidget {
  const SaberesFeedScreen({super.key});

  @override
  State<SaberesFeedScreen> createState() => _SaberesFeedScreenState();
}

class _SaberesFeedScreenState extends State<SaberesFeedScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _onScrollNotification(ScrollNotification n, SaberesFeedProvider provider) {
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
      provider.loadMore();
    }
    return false;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SaberesFeedProvider()..init()),
      ],
      child: Consumer<SaberesFeedProvider>(
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
                        // Sin AppBar (requerimiento)

                        // Search bar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                labelText: 'Buscar saberes',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: provider.setSearchQuery,
                            ),
                          ),
                        ),

                        // Encabezado sobre el carrusel
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.menu_book, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Libros destacados',
                                  style: AppTypography.textTheme.titleMedium?.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Carrusel de destacados (tipo "libre")
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 160,
                            child: Builder(builder: (context) {
                              final dest = provider.destacadosLibres;
                              if (provider.feedLoading && provider.saberes.isEmpty) {
                                return ListView.separated(
                                  key: const PageStorageKey('saberes_carousel_feed'),
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemBuilder: (_, __) => Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                                  ),
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemCount: 6,
                                );
                              }
                              if (dest.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('No hay libros destacados', style: TextStyle(color: AppColors.textSecondary)),
                                  ),
                                );
                              }
                              return ListView.separated(
                                key: const PageStorageKey('saberes_carousel_feed'),
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (itemCtx, i) => RepaintBoundary(
                                  key: ValueKey('carousel_${dest[i].id}'),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: SaberSquareCard(
                                      saber: dest[i],
                                      size: 140,
                                      onTap: () => SaberDetailOverlay.open(context, dest[i]),
                                    ),
                                  ),
                                ),
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemCount: dest.length,
                              );
                            }),
                          ),
                        ),

                        // Filter chips
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: FilterSegmentedChipsSaberes(
                              isLoggedIn: provider.isLoggedIn,
                              onLoginTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Inicia sesión para ver tus saberes y me gusta')),
                                );
                              },
                            ),
                          ),
                        ),

                        // Botón Publicar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final creado = await PublicarSaberPopularSheet.open(context);
                                  if (!mounted) return;
                                  if (creado != null) {
                                    await provider.refresh();
                                  }
                                },
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Publicar'),
                              ),
                            ),
                          ),
                        ),

                        // Content list
                        if (provider.feedLoading || provider.searching || provider.filterSwitching)
                          _SaberesSkeletonSliver(count: kIsWeb ? 8 : 6)
                        else if (provider.feedError != null)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _ErrorView(message: provider.feedError!, onRetry: provider.refresh),
                          )
                        else if (provider.searchError != null)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _ErrorView(message: provider.searchError!, onRetry: () => provider.setSearchQuery(provider.searchQuery)),
                          )
                        else if (provider.saberes.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyView(message: provider.searchQuery.isEmpty ? 'No hay saberes disponibles' : 'No hay resultados'),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index >= provider.saberes.length) return const SizedBox.shrink();
                                  final saber = provider.saberes[index];
                                  final bool isOwner = provider.isLoggedIn && saber.autorId == provider.currentUserId;
                                  final bool showMore = provider.isAdmin || (isOwner && provider.filtro == FeedFilter.mis);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: SaberCard(
                                      saber: saber,
                                      isLiked: provider.isLiked(saber.id),
                                      showMore: showMore,
                                      onTap: () => SaberDetailOverlay.open(context, saber),
                                      onLike: () => provider.toggleLike(saber.id),
                                      onShare: () async {
                                        final webUrl = Uri.parse('https://memoriaviva.app/saberes/${saber.id}');
                                        final resumen = saber.contenido.length > 120 ? saber.contenido.substring(0, 120) + '…' : saber.contenido;
                                        final message = '${saber.titulo}\n\n$resumen\n\nEnlace: $webUrl';
                                        await Share.share(message, subject: 'Saber – ${saber.titulo}');
                                        await provider.compartir(saber.id);
                                      },
                                      onReport: () => _showReportDialog(context, saber.id),
                                      onMore: () {
                                        if (showMore) {
                                          _showSaberActions(context, saberId: saber.id, isOwner: isOwner, provider: provider);
                                        }
                                      },
                                    ),
                                  );
                                },
                                childCount: provider.saberes.length,
                              ),
                            ),
                          ),

                        // Result count
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Resultados: ${provider.saberes.length}',
                                style: AppTypography.textTheme.labelMedium,
                              ),
                            ),
                          ),
                        ),

                        // Paginación incremental
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
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 8),
                          ),

                        // Bottom padding
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
                ),

                // Floating back-to-top
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    },
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textLight,
                    child: const Icon(Icons.arrow_upward),
                  ),
                ),

                // Loading/Error overlays (simple)
                if (provider.feedLoading)
                  const Positioned.fill(child: IgnorePointer(child: Center(child: CircularProgressIndicator()))),
                if (provider.feedError != null && !provider.feedLoading)
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 120,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text(provider.feedError!, style: const TextStyle(color: AppColors.error)),
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

extension on _SaberesFeedScreenState {
  void _showSaberActions(BuildContext context, {required String saberId, required bool isOwner, required SaberesFeedProvider provider}) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (provider.isAdmin || isOwner)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar saber'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final saber = provider.saberes.firstWhere((s) => s.id == saberId, orElse: () => provider.saberes.first);
                    final edited = await PublicarSaberPopularSheet.open(context, initialSaber: saber);
                    if (edited != null) {
                      provider.actualizarOptimista(edited);
                    }
                  },
                ),
              if (provider.isAdmin || isOwner)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Eliminar saber'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dctx) => AlertDialog(
                        title: const Text('¿Eliminar este saber?'),
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
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(const SnackBar(content: Text('Eliminando…')));
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      final ok = await provider.eliminarOptimista(saberId: saberId, usuarioId: userId);
                      messenger.hideCurrentSnackBar();
                      if (ok) {
                        messenger.showSnackBar(const SnackBar(backgroundColor: AppColors.success, content: Text('Saber eliminado')));
                      } else {
                        messenger.showSnackBar(const SnackBar(backgroundColor: AppColors.error, content: Text('Error al eliminar. Se revirtió el cambio.')));
                      }
                    });
                  },
                ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Reportar contenido'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await provider.reportar(saberId, 'Contenido inapropiado');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportDialog(BuildContext context, String saberId) async {
    final controller = TextEditingController();
    final provider = context.read<SaberesFeedProvider>();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reportar saber'),
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
              await provider.reportar(saberId, reason);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }
}

class _PlatformScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics();
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    if (kIsWeb) return Scrollbar(thumbVisibility: true, controller: details.controller, child: child);
    return child;
  }
}

class _SaberesSkeletonSliver extends StatelessWidget {
  final int count;
  const _SaberesSkeletonSliver({required this.count});
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          childCount: count,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message, style: AppTypography.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, style: AppTypography.textTheme.bodyLarge?.copyWith(color: AppColors.error), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

