import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import '../../widgets/navigation/animated_navigation_bar.dart';
import 'package:sidebarx/sidebarx.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/drawer/app_drawer.dart';
import '../../widgets/responsive/responsive_layout.dart';
import '../relatos/feed_screen.dart';
import '../mapa/map_screen.dart';
import '../relatos/publicar_relato_sheet.dart';
import '../../widgets/relatos/relato_detail_overlay.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../eventos/eventos_screen.dart';

class HomeScreen extends StatefulWidget {
  final String title;
  final int initialIndex;
  final String? mapFocusRelatoId;

  const HomeScreen({
    super.key,
    required this.title,
    this.initialIndex = 0,
    this.mapFocusRelatoId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<CurvedNavigationBarItem> _navigationItems = [];
  late final SidebarXController _controller;

  bool _isHandlingNavigation = false;

  @override
  void initState() {
    super.initState();
    _controller = SidebarXController(selectedIndex: 0, extended: true);
    _initNavigationItems();
    // Sincronizar índice del provider con la ruta inicial y manejar deeplink {'relatoId': id}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NavigationProvider>().setIndex(widget.initialIndex);
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['relatoId'] is String) {
        final String id = args['relatoId'] as String;
        // Abrir overlay cuando el feed esté visible
        RelatoDetailOverlay.open(context, null, relatoId: id);
      }
    });
  }

  void _initNavigationItems() {
    final selected = widget.initialIndex;
    _navigationItems.addAll([
      _buildNavItem(Icons.home_outlined, 'Inicio', 0, selected),
      _buildNavItem(Icons.map_outlined, 'Mapa', 1, selected),
      _buildNavItem(Icons.add_circle_outline, '', 2, selected),
      _buildNavItem(Icons.calendar_month_outlined, 'Eventos', 3, selected),
      _buildNavItem(Icons.menu_book_outlined, 'Biblioteca', 4, selected),
    ]);
  }

  int _mapDrawerIndexToNavIndex(int drawerIndex) {
    // Mapear índices del drawer a índices del navigation bar
    switch (drawerIndex) {
      case 0: return 0; // Inicio
      case 1: return 1; // Mapa
      case 3: return 3; // Calendario Cultural
      case 4: return 4; // Biblioteca
      case 5: return -1; // Chatbot abre ruta propia
      default: return -1; // No mapeado
    }
  }

  void _handleNavigationBarTap(int index) {
    if (_isHandlingNavigation) return;
    if (index == 2) {
      // Abrir overlay de publicación sin cambiar la pestaña
      PublicarRelatoSheet.open(context).then((published) {
        if (published == true) {
          // No-op: FeedProvider ya observa cambios y se actualizará
        }
      });
      return;
    }
    
    _isHandlingNavigation = true;
    final nav = context.read<NavigationProvider>();
    nav.setIndex(index);
    _isHandlingNavigation = false;
  }

  void _updateNavigationItems() {
    _navigationItems.clear();
    final selected = context.read<NavigationProvider>().selectedIndex;
    _navigationItems.addAll([
      _buildNavItem(Icons.home_outlined, 'Inicio', 0, selected),
      _buildNavItem(Icons.map_outlined, 'Mapa', 1, selected),
      _buildNavItem(Icons.add_circle_outline, '', 2, selected),
      _buildNavItem(Icons.calendar_month_outlined, 'Eventos', 3, selected),
      _buildNavItem(Icons.menu_book_outlined, 'Biblioteca', 4, selected),
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

  CurvedNavigationBarItem _buildNavItem(IconData icon, String label, int index, int selectedIndex) {
    final bool isSelected = selectedIndex == index;
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
                currentIndex: context.watch<NavigationProvider>().selectedIndex,
                items: _buildNavItemsForCurrent(),
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
        currentIndex: context.watch<NavigationProvider>().selectedIndex,
        items: _buildNavItemsForCurrent(),
        onTap: _handleNavigationBarTap,
      ),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    final currentIndex = context.watch<NavigationProvider>().selectedIndex;
    final focusId = context.watch<NavigationProvider>().mapFocusRelatoId;
    return IndexedStack(
      index: currentIndex,
      children: [
        const FeedScreen(),
        MapScreen(focusRelatoId: focusId),
        const _PublicarTab(),
        const _EventosTab(),
        const _BibliotecaTab(),
      ],
    );
  }

  List<CurvedNavigationBarItem> _buildNavItemsForCurrent() {
    final selected = context.watch<NavigationProvider>().selectedIndex;
    return [
      _buildNavItem(Icons.home_outlined, 'Inicio', 0, selected),
      _buildNavItem(Icons.map_outlined, 'Mapa', 1, selected),
      _buildNavItem(Icons.add_circle_outline, '', 2, selected),
      _buildNavItem(Icons.calendar_month_outlined, 'Eventos', 3, selected),
      _buildNavItem(Icons.menu_book_outlined, 'Biblioteca', 4, selected),
    ];
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


// Map tab reemplazado por MapScreen

class _PublicarTab extends StatelessWidget {
  const _PublicarTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Publicar', style: AppTypography.textTheme.headlineMedium),
    );
  }
}

class _EventosTab extends StatelessWidget {
  const _EventosTab();

  @override
  Widget build(BuildContext context) {
    return const EventosScreen();
  }
}

class _BibliotecaTab extends StatelessWidget {
  const _BibliotecaTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Biblioteca de Saberes', style: AppTypography.textTheme.headlineMedium),
    );
  }
}
