import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api/api_result.dart';
import '../services/api_service.dart';
import '../models/account.dart';
import 'budget_screen.dart';
import 'reflect_screen.dart';
import 'transactions_screen.dart';
import 'accounts_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0;
  List<Account> _accounts = [];
  bool _isLoading = true;
  bool _isExtended = true;
  bool _accessExists = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final accessExists = await apiService.simpleFin.doesAccessExist();
      final accountsData = await apiService.accounts.getAccounts();

      if (!accessExists.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to load access_token status: ${accessExists.error}')),
        );
        log("Failed to load access_token status: ${accessExists.error!}",
            level: 0);
      }

      setState(() {
        _accounts = accountsData.map((a) => Account.fromJson(a)).toList();
        _accessExists = accessExists.isSuccess ? accessExists.data! : true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  Future<void> _connectAccount(String accessCode) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    ApiResult<String> result =
        await apiService.simpleFin.connectAccounts(accessCode);
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
      log(result.error!);
    }
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const BudgetScreen();
      case 1:
        return const ReflectScreen();
      case 2:
        return const TransactionsScreen();
      case 3:
        return const AccountsScreen();
      default:
        return const BudgetScreen();
    }
  }

  Widget _buildAccountsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ),
          child: Text(
            'ACCOUNTS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._accounts.map((account) => _AccountItem(
                      name: account.name,
                      balance: account.currentBalance,
                    )),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: _accessExists
              ? OutlinedButton.icon(
                  onPressed: () async {
                    await _sync();
                  },
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Sync'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: _showAccessCodeDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Institution'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _sync() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    ApiResult<String> result = await apiService.simpleFin.sync();
    if (result.isSuccess) {
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
  }

  void _showAccessCodeDialog() async {
    String accessCode = '';
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Access Code'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Access Code'),
            onChanged: (value) {
              accessCode = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(accessCode);
                _connectAccount(accessCode);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access code submitted: ' + result)),
      );

      _loadData();
    }
  }

  Widget _buildSideNav(bool isExtended) {
    return NavigationRail(
      extended: isExtended,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      labelType: isExtended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      selectedIndex: _selectedIndex,
      destinations: const [
        NavigationRailDestination(
            icon: Icon(Icons.pie_chart), label: Text("Budget")),
        NavigationRailDestination(
            icon: Icon(Icons.insights), label: Text("Analytics")),
        NavigationRailDestination(
            icon: Icon(Icons.wallet), label: Text("Transactions")),
        NavigationRailDestination(
            icon: Icon(Icons.account_balance), label: Text("Accounts"))
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Budget"),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights), label: "Analytics"),
          BottomNavigationBarItem(
              icon: Icon(Icons.wallet), label: "Transactions"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance), label: "Accounts")
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;
    if (isWideScreen) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Budget App"),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              setState(() {
                _isExtended = !_isExtended;
              });
            },
          ),
        ),
        body: Row(
          children: <Widget>[
            SizedBox(
              width: _isExtended ? 240 : 0,
              child: Column(
                children: [
                  Expanded(
                    child: _buildSideNav(_isExtended),
                  ),
                  if (_isExtended)
                    Expanded(
                      flex: 2,
                      child: _buildAccountsList(),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _getSelectedScreen(),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: _getSelectedScreen(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}

class _AccountItem extends StatelessWidget {
  final String name;
  final double balance;

  const _AccountItem({
    required this.name,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    // For credit accounts: positive balance = debt (red), negative = overpaid (green)
    // For other accounts: positive balance = money (green), negative = overdrawn (red)
    final bool isGood = balance > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // Could navigate to account detail
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${balance.abs().toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isGood ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
