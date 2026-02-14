import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/create_budget_screen.dart';
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
      create: (_) => ApiService(baseUrl: 'http://localhost:8000'),
      child: MaterialApp(
        title: 'Budget App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _hasBudget = false;

  @override
  void initState() {
    super.initState();
    _checkForBudget();
  }

  Future<void> _checkForBudget() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final budget = await apiService.getCurrentBudget();
      
      setState(() {
        _hasBudget = budget != null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasBudget = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    return _hasBudget ? const MainLayoutScreen() : const CreateBudgetScreen();
  }
}
