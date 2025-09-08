import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/feed_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class FilterSegmentedChips extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onLoginTap;

  const FilterSegmentedChips({super.key, required this.isLoggedIn, required this.onLoginTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();

    Widget chip(String label, FeedFilter value, {bool enabled = true}) {
      final selected = provider.filtro == value;
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: ChoiceChip(
          label: Text(label, style: AppTypography.textTheme.labelLarge),
          selected: selected,
          onSelected: enabled ? (_) => provider.changeFilter(value) : null,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(color: selected ? AppColors.textLight : AppColors.textPrimary),
          backgroundColor: AppColors.surface,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          chip('Recientes', FeedFilter.recientes),
          chip('Populares', FeedFilter.populares),
          isLoggedIn
              ? chip('Mis relatos', FeedFilter.mis)
              : ActionChip(
                  label: Text('Inicia sesión', style: AppTypography.textTheme.labelLarge?.copyWith(color: AppColors.primaryDark)),
                  onPressed: onLoginTap,
                  backgroundColor: AppColors.surface,
                ),
        ],
      ),
    );
  }
}


