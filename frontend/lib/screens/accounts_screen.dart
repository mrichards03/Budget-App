import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/transaction.dart';
import '../models/account.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  double _totalBalance = 0.0;
  bool _isLoading = true;
  String? _selectedAccountFilter;

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

      final transactionsData =
          await apiService.transactions.getTransactions(limit: 500);
      final accountsData = await apiService.accounts.getAccounts();
      final totalBalance = await apiService.accounts.getTotalBalance();

      setState(() {
        _transactions = transactionsData
            .map((t) => Transaction.fromJson(t))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        _accounts = accountsData.map((a) => Account.fromJson(a)).toList();
        _totalBalance = totalBalance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load accounts: $e')),
        );
      }
    }
  }

  List<Transaction> get _filteredTransactions {
    if (_selectedAccountFilter == null) {
      return _transactions;
    }
    return _transactions
        .where((t) => t.accountId.toString() == _selectedAccountFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Header with total balance
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Accounts',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadData,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Total Balance Card
                          Card(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Balance',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '\$${_totalBalance.toStringAsFixed(2)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.account_balance,
                                    size: 48,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Account Filter Chips
                          if (_accounts.isNotEmpty)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  FilterChip(
                                    label: const Text('All Accounts'),
                                    selected: _selectedAccountFilter == null,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedAccountFilter = null;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ..._accounts.map((account) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: FilterChip(
                                        label: Text(account.name),
                                        selected: _selectedAccountFilter ==
                                            account.id.toString(),
                                        onSelected: (selected) {
                                          setState(() {
                                            _selectedAccountFilter = selected
                                                ? account.id.toString()
                                                : null;
                                          });
                                        },
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Transactions Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transactions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${_filteredTransactions.length} total',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Transactions List
                  _filteredTransactions.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long,
                                      size: 48, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No transactions found'),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final transaction =
                                    _filteredTransactions[index];
                                final account = _accounts.firstWhere(
                                  (a) => a.id == transaction.accountId,
                                  orElse: () => _accounts.isNotEmpty
                                      ? _accounts.first
                                      : Account(
                                          id: 0,
                                          plaidAccountId: '',
                                          plaidItemId: '',
                                          name: 'Unknown',
                                          accountType: '',
                                          accountSubtype: '',
                                          currentBalance: 0,
                                          createdAt: DateTime.now(),
                                        ),
                                );

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: transaction.amount < 0
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.green.withOpacity(0.1),
                                      child: Icon(
                                        transaction.amount < 0
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        color: transaction.amount < 0
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    title: Text(
                                      transaction.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(account.name),
                                        Text(
                                          '${transaction.date.month}/${transaction.date.day}/${transaction.date.year}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        if (transaction.category != null)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              transaction.category!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSecondaryContainer,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Text(
                                      '\$${transaction.amount.abs().toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: transaction.amount < 0
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _filteredTransactions.length,
                            ),
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}
