import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

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

  final Map<int, int> _personalIndexMap = {
    0: 0, // Inicio
    1: 1, // Mapa
    2: 2, // Crear Post
    3: 3, // Calendario Cultural
  };

  final Map<int, int> _accountIndexMap = {
    0: 200, // Perfil -> índice 200
    1: 201, // Ayuda -> índice 201
    2: 202, // Configuración -> índice 202
  };

  @override
  Widget build(BuildContext context) {
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
          icon: Icons.add_circle_outline,
          label: 'Crear Post',
          onTap: () => _handleItemTap(2),
        ),
        SidebarXItem(
          icon: Icons.calendar_month_outlined,
          label: 'Calendario Cultural',
          onTap: () => _handleItemTap(3),
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
    widget.onItemSelected?.call(index);
  }

  int _getSidebarIndex(int logicalIndex) {
    // Mapear índices lógicos a índices del SidebarX
    if (_selectedCategory == DrawerCategory.personal) {
      if (logicalIndex >= 0 && logicalIndex <= 3) {
        return logicalIndex; // 0-3 para items principales
      } else if (logicalIndex >= 200 && logicalIndex <= 202) {
        return 5 + (logicalIndex - 200); // 5-7 para items de cuenta
      }
    } else {
      if (logicalIndex >= 100 && logicalIndex <= 105) {
        return logicalIndex - 100; // 0-5 para juegos
      }
    }
    return 0;
  }
}