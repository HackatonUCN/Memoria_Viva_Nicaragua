import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chatbot')),
      body: Center(
        child: Text(
          'Pronto: Asistente cultural IA',
          style: AppTypography.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


