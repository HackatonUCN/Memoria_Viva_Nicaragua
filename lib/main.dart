import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'data/infrastructure/services/firebase_options.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializar Firebase solo si está disponible
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print('Firebase initialized successfully');
    }
  } catch (error) {
    if (kDebugMode) {
      print('Firebase initialization failed: $error');
      print('Continuing without Firebase...');
    }
  }

  // Inicializar ScreenUtil para diseño responsive
  await ScreenUtil.ensureScreenSize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Tamaño de diseño base (iPhone X)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Memoria Viva Nicaragua',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: const MyHomePage(title: 'Memoria Viva Nicaragua'),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'Platform: ${kIsWeb ? 'Web' : 'Mobile'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
