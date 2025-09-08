import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

class EmptyView extends StatelessWidget {
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyView({super.key, required this.message, this.actionText, this.onAction});

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
          if (actionText != null && onAction != null)
            ElevatedButton(onPressed: onAction, child: Text(actionText!))
        ],
      ),
    );
  }
}


