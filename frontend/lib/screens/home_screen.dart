import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'plaid_link_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // TODO: Store access token in shared preferences or state management
  String? _accessToken;

  final List<Widget> _screens = [
    const DashboardTab(),
    const TransactionsScreen(),
    const MLTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance),
            onPressed: () => _navigateToPlaidLink(context),
            tooltip: 'Connect Bank Account',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'ML Models',
          ),
        ],
      ),
    );
  }

  void _navigateToPlaidLink(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaidLinkScreen(
          onSuccess: () {},
        ),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dashboard, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('TODO: Add summary cards, charts, and insights'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement sync
            },
            icon: const Icon(Icons.sync),
            label: const Text('Sync Transactions'),
          ),
        ],
      ),
    );
  }
}

class MLTab extends StatelessWidget {
  const MLTab({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.psychology, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'ML Models',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('Train and manage machine learning models'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              // TODO: Show loading indicator
              try {
                final result = await apiService.trainModels();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Training result: ${result['message']}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.model_training),
            label: const Text('Train Models'),
          ),
          const SizedBox(height: 10),
          const Text('TODO: Display model metrics and status'),
        ],
      ),
    );
  }
}
