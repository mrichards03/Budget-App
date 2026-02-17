import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_layout_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => ApiService(baseUrl: 'http://10.0.0.97:8000'),
      child: MaterialApp(
        title: 'Budget App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 176, 6, 139),
            brightness: Brightness.dark
            ),
          useMaterial3: true,
        ),
        home: const MainLayoutScreen(),
      ),
    );
  }
}
