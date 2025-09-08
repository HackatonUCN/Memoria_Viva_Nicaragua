import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(message, textAlign: TextAlign.center, style: AppTypography.textTheme.titleMedium),
          ),
          if (onRetry != null) ElevatedButton(onPressed: onRetry, child: const Text('Reintentar'))
        ],
      ),
    );
  }
}


