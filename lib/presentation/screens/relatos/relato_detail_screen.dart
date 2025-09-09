import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/relato.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class RelatoDetailScreen extends StatelessWidget {
  final Relato relato;
  
  const RelatoDetailScreen({super.key, required this.relato});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(relato.titulo, style: AppTypography.textTheme.titleLarge),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (relato.multimedia.isNotEmpty)
              SizedBox(
                height: 260,
                child: PageView.builder(
                  itemCount: relato.multimedia.length,
                  itemBuilder: (context, index) {
                    final url = relato.multimedia[index].url;
                    return CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (c, _) => Container(color: AppColors.background),
                      errorWidget: (c, _, __) => const Icon(Icons.broken_image_outlined),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(relato.titulo, style: AppTypography.textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text('${relato.autorNombre} • ${relato.categoriaNombre}',
                      style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  Text(relato.contenido, style: AppTypography.textTheme.bodyMedium),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}


