import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar ScreenUtil para diseño responsive
  await ScreenUtil.ensureScreenSize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Memoria Viva Nicaragua - Web Test',
          theme: AppTheme.lightTheme,
          home: const WebTestPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class WebTestPage extends StatelessWidget {
  const WebTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memoria Viva Nicaragua - Web Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              '¡Bienvenido a Memoria Viva Nicaragua!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Versión Web Funcionando Correctamente',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Plataforma: ${kIsWeb ? 'Web' : 'Mobile'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡La aplicación web está funcionando!'),
                  ),
                );
              },
              child: const Text('Probar Funcionalidad'),
            ),
          ],
        ),
      ),
    );
  }
}
