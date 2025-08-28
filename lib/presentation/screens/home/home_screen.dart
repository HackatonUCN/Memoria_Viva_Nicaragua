import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import '../../widgets/navigation/animated_navigation_bar.dart';
import 'package:sidebarx/sidebarx.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/drawer/app_drawer.dart';
import '../../widgets/responsive/responsive_layout.dart';

class HomeScreen extends StatefulWidget {
  final String title;

  const HomeScreen({
    super.key,
    required this.title,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pageIndex = 0;
  final List<CurvedNavigationBarItem> _navigationItems = [];
  late final SidebarXController _controller;

  bool _isHandlingNavigation = false;

  @override
  void initState() {
    super.initState();
    _controller = SidebarXController(selectedIndex: 0, extended: true);
    _initNavigationItems();
  }

  void _initNavigationItems() {
    _navigationItems.addAll([
      _buildNavItem(Icons.home_outlined, 'Inicio', 0),
      _buildNavItem(Icons.map_outlined, 'Mapa', 1),
      _buildNavItem(Icons.add_circle_outline, '', 2),
      _buildNavItem(Icons.calendar_month_outlined, 'Eventos', 3),
      _buildNavItem(Icons.person_outline, 'Perfil', 4),
    ]);
  }

  int _mapDrawerIndexToNavIndex(int drawerIndex) {
    // Mapear índices del drawer a índices del navigation bar
    switch (drawerIndex) {
      case 0: return 0; // Inicio
      case 1: return 1; // Mapa
      case 2: return 2; // Crear Post
      case 3: return 3; // Calendario Cultural
      case 200: return 4; // Perfil
      default: return -1; // No mapeado
    }
  }

  void _handleNavigationBarTap(int index) {
    if (_isHandlingNavigation) return;
    
    _isHandlingNavigation = true;
    setState(() {
      _pageIndex = index;
      _updateNavigationItems();
    });
    _isHandlingNavigation = false;
  }

  void _updateNavigationItems() {
    _navigationItems.clear();
    _navigationItems.addAll([
      _buildNavItem(Icons.home_outlined, 'Inicio', 0),
      _buildNavItem(Icons.map_outlined, 'Mapa', 1),
      _buildNavItem(Icons.add_circle_outline, '', 2),
      _buildNavItem(Icons.calendar_month_outlined, 'Eventos', 3),
      _buildNavItem(Icons.person_outline, 'Perfil', 4),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIcon(IconData icon, bool isSelected) {
    return Icon(
      icon,
      color: isSelected ? AppColors.textLight : AppColors.primaryDark,
    );
  }

  CurvedNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _pageIndex == index;
    return CurvedNavigationBarItem(
      child: _buildIcon(icon, isSelected),
      label: label,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.textLight : AppColors.primaryDark,
      ),
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          AppDrawer(
            controller: _controller,
            onItemSelected: (index) {
              // Mapear índices del drawer a índices del navigation bar
              int navIndex = _mapDrawerIndexToNavIndex(index);
              if (navIndex != -1) {
                _handleNavigationBarTap(navIndex);
              }
            },
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  widget.title,
                  style: AppTypography.textTheme.titleLarge,
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
              ),
              bottomNavigationBar: AnimatedNavigationBar(
                currentIndex: _pageIndex,
                items: _navigationItems,
                onTap: _handleNavigationBarTap,
              ),
              body: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      drawer: AppDrawer(
        controller: _controller,
        onItemSelected: (index) {
          // Mapear índices del drawer a índices del navigation bar
          int navIndex = _mapDrawerIndexToNavIndex(index);
          if (navIndex != -1) {
            _handleNavigationBarTap(navIndex);
          }
          Navigator.of(context).pop(); // Cerrar el drawer
        },
      ),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTypography.textTheme.titleLarge,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      bottomNavigationBar: AnimatedNavigationBar(
        currentIndex: _pageIndex,
        items: _navigationItems,
        onTap: _handleNavigationBarTap,
      ),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo o imagen principal
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.nicaraguaGradient,
            ),
            child: Center(
              child: Text(
                'MV',
                style: AppTypography.textTheme.displayMedium?.copyWith(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Título de bienvenida
          Text(
            '¡Bienvenido a Memoria Viva!',
            style: AppTypography.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Subtítulo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Preservando y compartiendo la cultura nicaragüense',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Información de plataforma (solo para desarrollo)
          if (kDebugMode)
            Text(
              'Plataforma: ${kIsWeb ? 'Web' : 'Mobile'}',
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

          const SizedBox(height: 16),
          Text(
            'Sección actual: $_pageIndex',
            style: AppTypography.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildMobileLayout(),
      webBody: _buildWebLayout(),
      breakpoint: 800,
    );
  }
}
