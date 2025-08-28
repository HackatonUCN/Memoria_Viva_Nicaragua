import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../splash/cultural_background.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveHelper.isTablet(context) || ResponsiveHelper.isDesktop(context);

    return Stack(
      children: [
        // Fondo con gradiente
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.background,
              ],
            ),
          ),
        ),

        // Fondo cultural animado solo para web
        if (isWeb) const CulturalBackground(),

        // Contenido principal
        SafeArea(
          child: Padding(
            padding: ResponsiveHelper.getScreenPadding(context),
            child: Center(
              child: Container(
                width: ResponsiveHelper.getLoginCardWidth(context),
                constraints: BoxConstraints(
                  maxWidth: isWeb ? 550 : 500,
                  // No establecemos una altura mínima para que se ajuste al contenido
                ),
                decoration: isWeb ? BoxDecoration(
                  color: AppColors.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.05),
                      blurRadius: 40,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ) : null,
                padding: isWeb ? const EdgeInsets.symmetric(horizontal: 30, vertical: 15) : EdgeInsets.zero,
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
