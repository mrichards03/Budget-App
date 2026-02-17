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
  bool _isExtended = true;

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

      final accountsData = await apiService.accounts.getAccounts();
      final institutionsData = await apiService.plaid.getInstitutionsList();

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

  Widget _buildAccountsList() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
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
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                ..._accounts.map((account) => _AccountItem(
                      name: account.name,
                      balance: account.currentBalance,
                      accountType: account.accountType,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Add account from institution'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_balance, size: 18),
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
          );
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
            icon: Icon(Icons.account_balance), label: Text("Acccounts")),
      ],
      trailing: !isExtended
          ? null
          : SizedBox(
              width: 240, // match NavigationRail's width when extended
              child: _buildAccountsList(),
            ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Budget"),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights), label: "Analytics"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance), label: "Acccounts"),
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
            _buildSideNav(_isExtended),
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
  final String accountType;

  const _AccountItem({
    required this.name,
    required this.balance,
    required this.accountType,
  });

  @override
  Widget build(BuildContext context) {
    // For credit accounts: positive balance = debt (red), negative = overpaid (green)
    // For other accounts: positive balance = money (green), negative = overdrawn (red)
    final bool isGood = accountType == 'credit' ? balance < 0 : balance > 0;

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
