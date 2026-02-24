import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/transaction.dart';
import '../models/transaction_split.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../widgets/transaction_category_field.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Account> _accounts = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _editingTransactionId;
  // Track which transactions have their splits expanded
  final Set<int> _expandedSplits = {};

  // Sort state
  String _sortColumn = 'date'; // 'date' or 'account'
  bool _sortAscending = false; // false = descending (newest first)

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      final results = await Future.wait([
        apiService.transactions.getTransactions(),
        apiService.categories.getCategories(),
        apiService.accounts.getAccounts(),
      ]);

      setState(() {
        _transactions =
            (results[0]).map((json) => Transaction.fromJson(json)).toList();
        _categories =
            (results[1]).map((json) => Category.fromJson(json)).toList();
        _accounts = (results[2]).map((json) => Account.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  double get _unclearedBalance {
    return _transactions.where((t) => t.pending).fold(0.0, (sum, t) {
      final account = _accounts.firstWhere((a) => a.id == t.accountId,
          orElse: () => _accounts.first);
      if (account.accountType == 'credit') {
        return sum + t.amount; //TODO check for cc
      }
      return sum - t.amount;
    });
  }

  double get _workingBalance {
    return _accounts.fold(0.0, (sum, a) {
      return sum + a.currentBalance;
    });
  }

  double get _clearedBalance => _workingBalance - _unclearedBalance;

  String _getAccountName(String accountId) {
    final account = _accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => Account(
        id: '0',
        organizationDomain: 'Unknown',
        currencyCode: 'CAD',
        name: 'Unknown',
        accountType: AccountType.checking,
        currentBalance: 0,
        balanceDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    return account.name;
  }

  List<Transaction> _getSortedTransactions() {
    final sorted = List<Transaction>.from(_transactions);

    if (_sortColumn == 'date') {
      sorted.sort((a, b) => _sortAscending
          ? a.effectiveDate.compareTo(b.effectiveDate)
          : b.effectiveDate.compareTo(a.effectiveDate));
    } else if (_sortColumn == 'account') {
      sorted.sort((a, b) {
        final nameA = _getAccountName(a.accountId);
        final nameB = _getAccountName(b.accountId);
        return _sortAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
      });
    }

    return sorted;
  }

  void _toggleSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending =
            column == 'account'; // Account default to A-Z, Date to newest first
      }
    });
  }

  Future<void> _updateCategory(int transactionId, int subcategoryId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.transactions
          .categorizeTransaction(transactionId, subcategoryId);

      // Update the transaction locally instead of reloading everything
      setState(() {
        final index = _transactions.indexWhere((t) => t.id == transactionId);
        if (index != -1) {
          // Find the updated transaction data
          final oldTxn = _transactions[index];
          _transactions[index] = Transaction(
            id: oldTxn.id,
            accountId: oldTxn.accountId,
            amount: oldTxn.amount,
            effectiveDate: oldTxn.effectiveDate,
            name: oldTxn.name,
            memo: oldTxn.memo,
            subcategoryId: subcategoryId, // Updated
            pending: oldTxn.pending,
            createdAt: oldTxn.createdAt,
            isTransfer: oldTxn.isTransfer,
            transferAccountId: oldTxn.transferAccountId,
            predictedSubcategoryId: oldTxn.predictedSubcategoryId,
            predictedConfidence: oldTxn.predictedConfidence,
          );
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update category: $e';
      });
    }
  }

  Future<void> _trainModel() async {
    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.ml.retrainModel();

      if (!mounted) return;

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Model trained! Accuracy: ${(result['test_accuracy'] * 100).toStringAsFixed(1)}%',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else if (result['status'] == 'insufficient_data') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Training failed: ${result['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildBalanceBar(),
          _buildActionBar(),
          _buildTableHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text('Error: $_errorMessage'))
                    : _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text(
        'All Transactions',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBalanceBar() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          _buildBalanceItem(
            label: 'Cleared Balance',
            amount: _clearedBalance,
            format: currencyFormat,
          ),
          const SizedBox(width: 24),
          const Text('+', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 24),
          _buildBalanceItem(
            label: 'Uncleared Balance',
            amount: _unclearedBalance,
            format: currencyFormat,
          ),
          const SizedBox(width: 24),
          const Text('=', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 24),
          _buildBalanceItem(
            label: 'Working Balance',
            amount: _workingBalance,
            format: currencyFormat,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem({
    required String label,
    required double amount,
    required NumberFormat format,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          format.format(amount),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement add transaction
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Transaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement file import
            },
            icon: const Icon(Icons.file_upload, size: 18),
            label: const Text('File Import'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _trainModel,
            icon: const Icon(Icons.psychology, size: 18),
            label: const Text('Train ML Model'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('View'),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Transactions'),
              ),
              const PopupMenuItem(
                value: 'cleared',
                child: Text('Cleared Only'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending Only'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: InkWell(
              onTap: () => _toggleSort('account'),
              child: Row(
                children: [
                  const Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_sortColumn == 'account') ...[
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: InkWell(
              onTap: () => _toggleSort('date'),
              child: Row(
                children: [
                  const Text(
                    'DATE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_sortColumn == 'date') ...[
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'PAYEE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'CATEGORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'MEMO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(
            width: 100,
            child: Text(
              'OUTFLOW',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(
            width: 100,
            child: Text(
              'INFLOW',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(
            width: 96,
            child: Text(
              '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final sortedTransactions = _getSortedTransactions();

    // Build a flat list: parent rows and their optional split child rows
    final children = <Widget>[];
    for (final txn in sortedTransactions) {
      final isEditing = _editingTransactionId == txn.id;
      children.add(_buildTransactionRow(txn, isEditing));

      // Only show splits when expanded for this transaction
      if (txn.isSplit &&
          txn.splits != null &&
          _expandedSplits.contains(txn.id)) {
        for (final split in txn.splits!) {
          children.add(_buildSplitRow(split, txn));
        }
      }
    }

    return ListView(children: children);
  }

  Widget _buildSplitRow(dynamic split, Transaction parent) {
    // split is expected to be TransactionSplit model
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final subName = _getSubcategoryName(split.subcategoryId);
    final isOutflow = (split.amount ?? 0) < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 150), // account col empty
          SizedBox(width: 100), // date col empty
          const Expanded(flex: 2, child: SizedBox()), // payee empty to align
          Expanded(
            flex: 2,
            child: Text(
              subName ?? 'Unknown',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              split.memo ?? '',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              isOutflow ? currencyFormat.format(split.amount.abs()) : '',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: Colors.red),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              !isOutflow ? currencyFormat.format(split.amount.abs()) : '',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: Colors.green),
            ),
          ),
          SizedBox(
            width: 96,
            child: IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () {
                _openSplitDialog(parent);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Transaction transaction, bool isEditing) {
    final dateFormat = DateFormat('MM/dd/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final isOutflow = transaction.amount < 0; //TODO check for cc
    final isInflow = transaction.amount > 0;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              _getAccountName(transaction.accountId),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              dateFormat.format(transaction.effectiveDate),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              transaction.name,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildCategoryField(transaction, isEditing),
          ),
          Expanded(
            flex: 2,
            child: Text(
              //TODO: Implement memo
              transaction.memo ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              isOutflow ? currencyFormat.format(transaction.amount.abs()) : '',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              isInflow ? currencyFormat.format(transaction.amount.abs()) : '',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
              ),
            ),
          ),
          SizedBox(
            width: 96,
            child: Center(
              child: (transaction.isSplit &&
                      transaction.splits != null &&
                      transaction.splits!.isNotEmpty)
                  ? IconButton(
                      icon: Icon(
                        _expandedSplits.contains(transaction.id)
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_expandedSplits.contains(transaction.id)) {
                            _expandedSplits.remove(transaction.id);
                          } else {
                            _expandedSplits.add(transaction.id);
                          }
                        });
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.call_split, size: 18),
                      onPressed: () {
                        _openSplitDialog(transaction);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSplitDialog(Transaction transaction) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    // Prepare initial rows: existing splits or two empty rows
    List<Map<String, dynamic>> rows = [];
    if (transaction.isSplit &&
        transaction.splits != null &&
        transaction.splits!.isNotEmpty) {
      rows = transaction.splits!
          .map((s) => {
                'id': s.id,
                'subcategory_id': s.subcategoryId,
                'amount': s.amount,
                'memo': s.memo,
              })
          .toList();
    } else {
      // default two rows dividing evenly
      final half = (transaction.amount / 2);
      rows = [
        {'subcategory_id': null, 'amount': half, 'memo': null},
        {
          'subcategory_id': null,
          'amount': transaction.amount - half,
          'memo': null
        },
      ];
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          double total() =>
              rows.fold(0.0, (s, r) => s + (r['amount'] as double));

          String? validationError() {
            // Allow empty rows: saving with zero rows will remove all splits
            if (rows.isEmpty) return null;

            if (double.parse(total().toStringAsFixed(2)) !=
                double.parse(transaction.amount.toStringAsFixed(2))) {
              return 'Split amounts must sum to ${NumberFormat.currency(symbol: '\$').format(transaction.amount)}';
            }

            return null;
          }

          return AlertDialog(
            title: const Text('Split Transaction'),
            content: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Original: ${NumberFormat.currency(symbol: '\$').format(transaction.amount)}'),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: rows.length,
                      itemBuilder: (context, idx) {
                        final row = rows[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  value: row['subcategory_id'],
                                  items: _categories
                                      .expand((c) => c.subcategories ?? [])
                                      .map((s) => DropdownMenuItem<int>(
                                            value: s.id,
                                            child: Text(s.name),
                                          ))
                                      .toList(),
                                  onChanged: (val) => setState(
                                      () => row['subcategory_id'] = val),
                                  decoration: const InputDecoration(
                                      labelText: 'Subcategory'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: (row['amount'] as double)
                                      .toStringAsFixed(2),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                      labelText: 'Amount'),
                                  onChanged: (v) {
                                    final parsed = double.tryParse(v) ?? 0.0;
                                    setState(() => row['amount'] = parsed);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  initialValue: row['memo'] ?? '',
                                  decoration:
                                      const InputDecoration(labelText: 'Memo'),
                                  onChanged: (v) =>
                                      setState(() => row['memo'] = v),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => setState(() {
                                  rows.removeAt(idx);
                                }),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => setState(() => rows.add({
                              'subcategory_id': null,
                              'amount': 0.0,
                              'memo': null
                            })),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Split'),
                      ),
                      const SizedBox(width: 12),
                      Text(
                          'Total: ${NumberFormat.currency(symbol: '\$').format(total())}'),
                      const SizedBox(width: 12),
                      if (validationError() != null)
                        Text(validationError()!,
                            style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: validationError() != null
                    ? null
                    : () async {
                        // Build API payload
                        final payload = rows
                            .map((r) => {
                                  'subcategory_id': r['subcategory_id'],
                                  'amount': r['amount'],
                                  'memo': r['memo'],
                                })
                            .toList();

                        try {
                          await apiService.transactions.setTransactionSplits(
                              transaction.id, payload,
                              replaceExisting: true);

                          // Update local transaction with new splits
                          setState(() {
                            final idx = _transactions
                                .indexWhere((t) => t.id == transaction.id);
                            if (idx != -1) {
                              final updatedSplits = rows.isNotEmpty
                                  ? rows
                                      .asMap()
                                      .entries
                                      .map((e) => TransactionSplit(
                                            id: e.key,
                                            subcategoryId:
                                                e.value['subcategory_id'] ?? 0,
                                            amount: e.value['amount'] as double,
                                            memo: e.value['memo'],
                                            createdAt: DateTime.now(),
                                          ))
                                      .toList()
                                  : null;

                              _transactions[idx] = Transaction(
                                id: transaction.id,
                                accountId: transaction.accountId,
                                amount: transaction.amount,
                                effectiveDate: transaction.effectiveDate,
                                name: transaction.name,
                                memo: transaction.memo,
                                subcategoryId: null,
                                pending: transaction.pending,
                                createdAt: transaction.createdAt,
                                isTransfer: transaction.isTransfer,
                                transferAccountId:
                                    transaction.transferAccountId,
                                predictedSubcategoryId:
                                    transaction.predictedSubcategoryId,
                                predictedConfidence:
                                    transaction.predictedConfidence,
                                isSplit: updatedSplits != null,
                                splits: updatedSplits,
                              );
                            }
                          });

                          Navigator.of(context).pop(true);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Failed to save splits: $e')));
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );

    if (result == true) {
      // Optionally reload data from server for accuracy
      await _loadData();
    }
  }

  String? _getSubcategoryName(int? subcategoryId) {
    if (subcategoryId == null) return null;

    for (final category in _categories) {
      if (category.subcategories != null) {
        for (final subcategory in category.subcategories!) {
          if (subcategory.id == subcategoryId) {
            return subcategory.name;
          }
        }
      }
    }
    return null;
  }

  Widget _buildCategoryField(Transaction transaction, bool isEditing) {
    if (transaction.isSplit) {
      final subName = _getSubcategoryName(transaction.subcategoryId);
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          subName ?? 'Split',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      );
    }

    return TransactionCategoryField(
      transaction: transaction,
      categories: _categories,
      isEditing: isEditing,
      onTap: () {
        setState(() {
          _editingTransactionId = transaction.id;
        });
      },
      onCategorySelected: (subcategoryId) async {
        await _updateCategory(transaction.id, subcategoryId);
      },
      onEditingComplete: () {
        setState(() {
          _editingTransactionId = null;
        });
      },
    );
  }
}
