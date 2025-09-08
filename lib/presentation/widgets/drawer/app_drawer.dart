import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../../config/app_router.dart';
import '../../providers/auth_provider.dart';

enum DrawerCategory { personal, games }

class AppDrawer extends StatefulWidget {
  final SidebarXController controller;
  final ValueChanged<int>? onItemSelected;

  const AppDrawer({
    super.key,
    required this.controller,
    this.onItemSelected,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  DrawerCategory _selectedCategory = DrawerCategory.personal;
  int _selectedIndex = 0;
  bool _loggingOut = false;

  final Map<int, int> _personalIndexMap = {
    0: 0, // Inicio
    1: 1, // Mapa
    2: 2, // Crear Post
    3: 3, // Calendario Cultural
  };

  final Map<int, int> _accountIndexMap = {
    0: 201, // Ayuda
    1: 202, // Configuración
  };

  @override
  Widget build(BuildContext context) {
    // Sincronizar selección con NavigationProvider (dos vías)
    final navIndex = context.watch<NavigationProvider>().selectedIndex;
    if (_selectedCategory == DrawerCategory.personal) {
      int? desiredLogical;
      if (navIndex == 0 || navIndex == 1 || navIndex == 3 || navIndex == 4) {
        desiredLogical = navIndex;
      }
      if (desiredLogical != null) {
        final sidebarIndex = _getSidebarIndex(desiredLogical);
        if (sidebarIndex >= 0) {
          widget.controller.selectIndex(sidebarIndex);
        }
      }
    }
    return SidebarX(
      controller: widget.controller,
      theme: SidebarXTheme(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: AppTypography.textTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
        ),
        selectedTextStyle: AppTypography.textTheme.titleMedium?.copyWith(
          color: AppColors.textLight,
          fontWeight: FontWeight.bold,
        ),
        itemTextPadding: const EdgeInsets.only(left: 30),
        selectedItemTextPadding: const EdgeInsets.only(left: 30),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.transparent),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.28),
              blurRadius: 30,
            )
          ],
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: 20,
        ),
        selectedIconTheme: IconThemeData(
          color: AppColors.textLight,
          size: 20,
        ),
      ),
      extendedTheme: SidebarXTheme(
        width: 280,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      headerBuilder: (context, extended) {
        return _buildHeader(extended);
      },
      items: _buildSidebarItems(extended: widget.controller.extended),
      footerBuilder: (context, extended) {
        return _buildFooter(extended);
      },
      footerDivider: Divider(color: AppColors.primary.withOpacity(0.3), height: 1),
    );
  }

  Widget _buildHeader(bool extended) {
    if (!extended) {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.nicaraguaGradient,
            ),
            child: Center(
              child: Text(
                'MV',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Si por alguna razón el ancho real es muy pequeño, usar versión compacta
        if (constraints.maxWidth < 120) {
          return Container(
            height: 100,
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.nicaraguaGradient,
                ),
                child: Center(
                  child: Text(
                    'MV',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          height: 180,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Logo y título (extendido)
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.nicaraguaGradient,
                    ),
                    child: Center(
                      child: Text(
                        'MV',
                        style: AppTypography.textTheme.titleLarge?.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Memoria Viva\nNicaragua',
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildCategorySelector(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCategoryButton(
              'Personal',
              DrawerCategory.personal,
              Icons.person_outline,
            ),
          ),
          Expanded(
            child: _buildCategoryButton(
              'Juegos',
              DrawerCategory.games,
              Icons.games_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String title, DrawerCategory category, IconData icon) {
    final bool isSelected = _selectedCategory == category;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool showLabel = constraints.maxWidth > 140;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 12,
              horizontal: showLabel ? 16 : 10,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppColors.textLight : AppColors.textPrimary,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.titleSmall?.copyWith(
                        color: isSelected ? AppColors.textLight : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<SidebarXItem> _buildSidebarItems({required bool extended}) {
    List<SidebarXItem> items = [];

    if (_selectedCategory == DrawerCategory.personal) {
      // Items personales
      items.addAll([
        SidebarXItem(
          icon: Icons.home_outlined,
          label: 'Inicio',
          onTap: () => _handleItemTap(0),
        ),
        SidebarXItem(
          icon: Icons.map_outlined,
          label: 'Mapa',
          onTap: () => _handleItemTap(1),
        ),
        SidebarXItem(
          icon: Icons.calendar_month_outlined,
          label: 'Calendario Cultural',
          onTap: () => _handleItemTap(3),
        ),
        SidebarXItem(
          icon: Icons.menu_book_outlined,
          label: 'Biblioteca de Saberes',
          onTap: () => _handleItemTap(4),
        ),
        SidebarXItem(
          icon: Icons.smart_toy_outlined,
          label: 'Chatbot',
          onTap: () => _handleItemTap(5),
        ),
      ]);
    } else {
      // Items de juegos
      items.addAll([
        SidebarXItem(
          icon: Icons.games_outlined,
          label: 'Ahorcado',
          onTap: () => _handleItemTap(100),
        ),
        SidebarXItem(
          icon: Icons.quiz_outlined,
          label: 'Adivinanzas',
          onTap: () => _handleItemTap(101),
        ),
        SidebarXItem(
          icon: Icons.format_quote_outlined,
          label: 'Complete el Dicho',
          onTap: () => _handleItemTap(102),
        ),
        SidebarXItem(
          icon: Icons.help_outline,
          label: 'Trivia',
          onTap: () => _handleItemTap(103),
        ),
        SidebarXItem(
          icon: Icons.grid_view_outlined,
          label: 'Sopa de Letras',
          onTap: () => _handleItemTap(104),
        ),
        SidebarXItem(
          icon: Icons.extension_outlined,
          label: 'Rompecabezas',
          onTap: () => _handleItemTap(105),
        ),
      ]);
    }

    return items;
  }

  Widget _buildFooter(bool extended) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (extended)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
              child: Text(
                'Cuenta y Ayuda',
                style: AppTypography.textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          _buildFooterItem(
            icon: Icons.person_outline,
            title: 'Perfil',
            index: 200,
            extended: extended,
          ),
          _buildFooterItem(
            icon: Icons.help_outline,
            title: 'Ayuda',
            index: 201,
            extended: extended,
          ),
          _buildFooterItem(
            icon: Icons.settings_outlined,
            title: 'Configuración',
            index: 202,
            extended: extended,
          ),
          const SizedBox(height: 8),
          _buildLogoutButton(extended: extended),
        ],
      ),
    );
  }

  Widget _buildFooterItem({
    required IconData icon,
    required String title,
    required int index,
    required bool extended,
  }) {
    final bool isSelected = _selectedIndex == index;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool showLabel = extended && constraints.maxWidth > 120;
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _handleItemTap(index),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 10,
              horizontal: showLabel ? 10 : 6,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: showLabel
                ? Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected ? AppColors.textLight : AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textTheme.titleMedium?.copyWith(
                            color: isSelected ? AppColors.textLight : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _handleItemTap(int index) {
    setState(() {
      _selectedIndex = index;
      widget.controller.selectIndex(_getSidebarIndex(index));
    });
    if (index == 200) {
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed(AppRoutes.perfil);
      return;
    }
    if (index == 4) {
      context.read<NavigationProvider>().setIndex(4);
      Navigator.of(context).pop();
      widget.onItemSelected?.call(index);
      return;
    }
    if (index == 5) {
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed(AppRoutes.chatbot);
      return;
    }
    widget.onItemSelected?.call(index);
  }

  int _getSidebarIndex(int logicalIndex) {
    // Mapear índices lógicos a índices del SidebarX
    if (_selectedCategory == DrawerCategory.personal) {
      // Orden visual de los items personales en el SidebarX
      // [Inicio(0), Mapa(1), Calendario(3), Biblioteca(4), Chatbot(5)]
      final List<int> order = [0, 1, 3, 4, 5];
      final int idx = order.indexOf(logicalIndex);
      return idx >= 0 ? idx : 0;
    } else {
      if (logicalIndex >= 100 && logicalIndex <= 105) {
        return logicalIndex - 100; // 0-5 para juegos
      }
    }
    return 0;
  }

  Widget _buildLogoutButton({required bool extended}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _loggingOut
          ? null
          : () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Quieres cerrar la sesión actual?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
              ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Cerrar sesión')),
            ],
          ),
        );
        if (confirmed != true) return;

        setState(() {
          _loggingOut = true;
        });
        try {
          await context.read<AuthProvider>().signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesión cerrada')),
          );
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cerrar sesión: $e')),
          );
          setState(() {
            _loggingOut = false;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            if (_loggingOut)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.logout, color: AppColors.textPrimary, size: 20),
            if (extended) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _loggingOut ? 'Cerrando sesión...' : 'Cerrar sesión',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.titleMedium,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}