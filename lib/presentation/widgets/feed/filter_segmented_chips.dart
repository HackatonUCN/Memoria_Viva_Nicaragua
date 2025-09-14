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
    final filtro = context.select<FeedProvider, FeedFilter>((p) => p.filtro);

    Widget chip(String label, FeedFilter value, {bool enabled = true}) {
      final selected = filtro == value;
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: ChoiceChip(
          label: Text(label, style: AppTypography.textTheme.labelLarge),
          selected: selected,
          onSelected: enabled
              ? (_) {
                  // Evitar bloquear el hilo de UI: delegar cambio tras frame
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final p = context.read<FeedProvider>();
                    p.setFiltro(value);
                  });
                }
              : null,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isNarrow = constraints.maxWidth < 420;
          final chips = <Widget>[
            chip('Recientes', FeedFilter.recientes),
            chip('Populares', FeedFilter.populares),
            if (isLoggedIn) chip('Mis relatos', FeedFilter.mis) else ActionChip(
              label: Text('Inicia sesión', style: AppTypography.textTheme.labelLarge?.copyWith(color: AppColors.primaryDark)),
              onPressed: onLoginTap,
              backgroundColor: AppColors.surface,
            ),
            if (isLoggedIn) chip('Me gusta', FeedFilter.liked),
          ];
          if (isNarrow) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [const SizedBox(width: 4), ...chips.map((w) => Padding(padding: const EdgeInsets.only(right: 8), child: w))]),
            );
          }
          return Wrap(spacing: 8, children: chips);
        },
      ),
    );
  }
}


