import 'package:flutter/material.dart';
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

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

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
                  final ok = await PublicarRelatoSheet.open(context, initialRelato: relato);
                  if (ok == true) {
                    await provider.refresh();
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
                  final usecases = UseCases.resolve();
                  final userId = provider.currentUserId;
                  if (userId == null) return;
                  messenger.showSnackBar(const SnackBar(content: Text('Eliminando...')));
                  final res = await usecases.relatos.eliminar.execute(usuarioId: userId, relatoId: relato.id);
                  messenger.hideCurrentSnackBar();
                  if (res.isSuccess) {
                    messenger.showSnackBar(const SnackBar(backgroundColor: AppColors.success, content: Text('Relato eliminado')));
                    await provider.refresh();
                  } else {
                    messenger.showSnackBar(SnackBar(backgroundColor: AppColors.error, content: Text(res.errorOrNull?.message ?? 'Error al eliminar')));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeedProvider()..init(),
      child: Consumer<FeedProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: CustomScrollView(
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: FilterSegmentedChips(
                      isLoggedIn: provider.isLoggedIn,
                      onLoginTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => PublicarRelatoSheet.open(context),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Publicar'),
                      ),
                    ),
                  ),
                ),
                if (provider.feedLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.feedError != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(message: provider.feedError!, onRetry: provider.refresh),
                  )
                else if (provider.relatos.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyView(message: 'No hay relatos disponibles'),
                  )
                else
                  SliverList.builder(
                    itemCount: provider.relatos.length,
                    itemBuilder: (context, index) {
                      final relato = provider.relatos[index];
                      final showMore = provider.filtro == FeedFilter.mis && provider.isLoggedIn && relato.autorId == provider.currentUserId;
                      return RelatoCard(
                        relato: relato,
                        onTap: () => RelatoDetailOverlay.open(context, relato),
                        onLike: () async {},
                        onShare: () async {},
                        onReport: () => _showReportDialog(context, relato.id),
                        showMore: showMore,
                        onMore: showMore ? () => _showOwnerActions(context, provider, relato) : null,
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}


