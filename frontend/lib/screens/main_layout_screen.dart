import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/account.dart';
import '../models/institution.dart';
import 'budget_screen.dart';
import 'reflect_screen.dart';
import 'accounts_screen.dart';
import 'plaid_link_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0;
  List<Account> _accounts = [];
  List<Institution> _institutions = [];
  bool _isLoading = true;

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

      final accountsData = await apiService.getAccounts();
      final institutionsData = await apiService.getInstitutionsList();

      setState(() {
        _accounts = accountsData.map((a) => Account.fromJson(a)).toList();
        _institutions =
            institutionsData.map((i) => Institution.fromJson(i)).toList();
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

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const BudgetScreen();
      case 1:
        return const ReflectScreen();
      case 2:
        return const AccountsScreen();
      default:
        return const BudgetScreen();
    }
  }

  void _navigateToPlaidLink() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaidLinkScreen(
          onSuccess: () {
            _loadData();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Budget App',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Navigation
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _NavItem(
                        icon: Icons.pie_chart,
                        label: 'Budget',
                        selected: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                      const SizedBox(height: 4),
                      _NavItem(
                        icon: Icons.insights,
                        label: 'Reflect',
                        selected: _selectedIndex == 1,
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                      const SizedBox(height: 4),
                      _NavItem(
                        icon: Icons.account_balance,
                        label: 'Accounts',
                        selected: _selectedIndex == 2,
                        onTap: () => setState(() => _selectedIndex = 2),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Accounts Section
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    'ACCOUNTS',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ),
                                ..._accounts.map((account) => _AccountItem(
                                      name: account.name,
                                      balance: account.currentBalance,
                                    )),
                                const SizedBox(height: 12),

                                // Add Institution Button
                                OutlinedButton.icon(
                                  onPressed: _navigateToPlaidLink,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Institution'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),

                                // Add Account Button (only if institutions exist)
                                if (_institutions.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      // TODO: Implement add account from existing institution
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Add account from institution'),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.account_balance,
                                        size: 18),
                                    label: const Text('Add Account'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _getSelectedScreen(),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.secondaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
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
    final isNegative = balance < 0;

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
                        color: isNegative ? Colors.red : Colors.green,
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
