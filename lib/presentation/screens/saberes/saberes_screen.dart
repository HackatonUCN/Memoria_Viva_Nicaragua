import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/saber_popular.dart';
import '../../widgets/saberes/saber_square_card.dart';
import '../../widgets/saberes/saber_card.dart';
import '../../providers/saberes/saberes_provider.dart';
import 'publicar_saber_popular_sheet.dart';

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

class _PlatformScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
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

class SaberesScreen extends StatelessWidget {
  const SaberesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SaberesProvider()..init()),
      ],
      child: const _SaberesSliverContent(),
    );
  }
}

class _SaberesSliverContent extends StatefulWidget {
  const _SaberesSliverContent();

  @override
  State<_SaberesSliverContent> createState() => _SaberesSliverContentState();
}

class _SaberesSliverContentState extends State<_SaberesSliverContent> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'reciente'; // reciente, populares, me_gusta, mis_saberes
  String? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: _PlatformScrollBehavior(),
          child: CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                backgroundColor: AppColors.primary,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                floating: true,
                snap: true,
                title: Text(
                  'Biblioteca de Saberes',
                  style: AppTypography.textTheme.headlineSmall?.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: true,
                iconTheme: const IconThemeData(color: AppColors.textLight),
              ),

              // Carrusel de Saberes Destacados
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: Consumer<SaberesProvider>(
                    builder: (ctx, provider, __) {
                      final saberesDest
= provider.saberesDestacados;
                      if (provider.loading) {
                        return ListView.separated(
                          key: const PageStorageKey('saberes_carousel'),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (_, __) => Container(
                            width: 140, 
                            height: 140, 
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemCount: 6,
                        );
                      }
                      
                      if (saberesDest.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No hay saberes destacados disponibles',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        key: const PageStorageKey('saberes_carousel'),
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (itemCtx, i) => RepaintBoundary(
                          key: ValueKey('carousel_${saberesDest[i].id}'),
                          child: _KeepAlive(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: SaberSquareCard(
                                saber: saberesDest[i],
                                onTap: () {
                                  // TODO: Abrir detalle del saber
                                },
                              ),
                            ),
                          ),
                        ),
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemCount: saberesDest.length,
                      );
                    },
                  ),
                ),
              ),

              // Barra de búsqueda
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: _SaberesSearchBar(
                    controller: _searchController,
                    onChanged: (query) {
                      // TODO: Implementar búsqueda con debounce
                    },
                  ),
                ),
              ),

              // Chips de filtro (Reciente, Populares, etc.)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _SaberesFilterChips(
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      // TODO: Aplicar filtro
                    },
                  ),
                ),
              ),

              // Chips de categorías
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _SaberesCategoryChips(
                    selectedCategoryId: _selectedCategoryId,
                    onCategoryChanged: (categoryId) {
                      setState(() {
                        _selectedCategoryId = categoryId;
                      });
                      // TODO: Aplicar filtro por categoría
                    },
                  ),
                ),
              ),

              // Botón Publicar (igual que en el feed)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final SaberPopular? creado = await PublicarSaberPopularSheet.open(context);
                        if (!context.mounted) return;
                        if (creado != null) {
                          // Refrescar lista si se creó para reflejar optimista o datos reales cuando lleguen
                          await context.read<SaberesProvider>().refresh();
                        }
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Publicar'),
                    ),
                  ),
                ),
              ),

              // Lista de Saberes Cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: Consumer<SaberesProvider>(
                  builder: (context, provider, child) {
                    if (provider.loading && provider.saberes.isEmpty) {
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: _SaberCardSkeleton(),
                          ),
                          childCount: 5,
                        ),
                      );
                    }

                    if (provider.saberes.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book_outlined,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay saberes disponibles',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final saber = provider.saberes[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SaberCard(
                              saber: saber,
                              onTap: () {
                                // TODO: Abrir detalle del saber
                              },
                              onLike: () {
                                // TODO: Implementar like
                              },
                              onShare: () {
                                // TODO: Implementar compartir
                              },
                            ),
                          );
                        },
                        childCount: provider.saberes.length,
                      ),
                    );
                  },
                ),
              ),

              // Espaciado inferior
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para la barra de búsqueda
class _SaberesSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _SaberesSearchBar({
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Buscar saberes populares...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

// Widget para chips de filtro
class _SaberesFilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const _SaberesFilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'key': 'reciente', 'label': 'Reciente', 'icon': Icons.schedule},
      {'key': 'populares', 'label': 'Populares', 'icon': Icons.trending_up},
      {'key': 'me_gusta', 'label': 'Me gusta', 'icon': Icons.favorite_outline},
      {'key': 'mis_saberes', 'label': 'Mis saberes', 'icon': Icons.person_outline},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 16,
                    color: isSelected ? AppColors.textLight : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      color: isSelected ? AppColors.textLight : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              onSelected: (_) => onFilterChanged(filter['key'] as String),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.accent,
              checkmarkColor: AppColors.textLight,
               side: BorderSide(
                 color: isSelected ? AppColors.accent : AppColors.primary.withOpacity(0.3),
                 width: 1,
               ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Widget para chips de categorías
class _SaberesCategoryChips extends StatelessWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;

  const _SaberesCategoryChips({
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Obtener categorías de saberes del provider
    final categories = [
      {'id': null, 'name': 'Todas'},
      {'id': 'saber_recetas', 'name': 'Recetas'},
      {'id': 'saber_artesanias', 'name': 'Artesanías'},
      {'id': 'saber_medicina_tradicional', 'name': 'Medicina'},
      {'id': 'saber_musica_danza', 'name': 'Música y Danza'},
      {'id': 'saber_dichos_refranes', 'name': 'Dichos'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategoryId == category['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(
                category['name'] as String,
                style: TextStyle(
                  color: isSelected ? AppColors.textLight : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              onSelected: (_) => onCategoryChanged(category['id'] as String?),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
               side: BorderSide(
                 color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.3),
                 width: 1,
               ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Widget skeleton para carga
class _SaberCardSkeleton extends StatelessWidget {
  const _SaberCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
