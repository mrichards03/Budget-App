import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Account> _accounts = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _editingTransactionId;

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

  double get _clearedBalance {
    return _transactions
        .where((t) => !t.pending)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _unclearedBalance {
    return _transactions
        .where((t) => t.pending)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _workingBalance => _clearedBalance + _unclearedBalance;

  String _getAccountName(int accountId) {
    final account = _accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => Account(
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
    return account.name;
  }

  Future<void> _updateCategory(int transactionId, int subcategoryId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.transactions
          .categorizeTransaction(transactionId, subcategoryId);

      // Reload transactions to get updated data
      await _loadData();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update category: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
        'All Accounts',
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
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 150,
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(
            width: 100,
            child: Text(
              'DATE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
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
                color: Colors.black54,
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
                color: Colors.black54,
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
                color: Colors.black54,
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
                color: Colors.black54,
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
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final isEditing = _editingTransactionId == transaction.id;

        return _buildTransactionRow(transaction, isEditing);
      },
    );
  }

  Widget _buildTransactionRow(Transaction transaction, bool isEditing) {
    final dateFormat = DateFormat('MM/dd/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final isOutflow = transaction.amount < 0;
    final isInflow = transaction.amount > 0;

    return Container(
      decoration: BoxDecoration(
        color: isEditing ? Colors.blue.shade50 : Colors.white,
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
              dateFormat.format(transaction.date),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              transaction.merchantName ?? transaction.name,
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
              transaction.categoryDetailed ?? '',
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
              isInflow ? currencyFormat.format(transaction.amount) : '',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
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
    if (isEditing) {
      return _buildCategoryDropdown(transaction);
    }

    final subcategoryName = _getSubcategoryName(transaction.subcategoryId);

    return GestureDetector(
      onTap: () {
        setState(() {
          _editingTransactionId = transaction.id;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            if (subcategoryName != null) ...[
              Icon(
                Icons.label,
                size: 16,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                subcategoryName ??
                    transaction.predictedCategory ??
                    'Ready to Assign',
                style: TextStyle(
                  fontSize: 14,
                  color: subcategoryName == null
                      ? Colors.grey.shade600
                      : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(Transaction transaction) {
    // Use the subcategory ID from the transaction
    int? currentValue = transaction.subcategoryId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: currentValue,
          isExpanded: true,
          hint: const Text('Select Category'),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Ready to Assign'),
            ),
            ..._buildCategoryMenuItems(),
          ],
          onChanged: (subcategoryId) async {
            if (subcategoryId != null) {
              await _updateCategory(transaction.id, subcategoryId);
            }
            setState(() {
              _editingTransactionId = null;
            });
          },
        ),
      ),
    );
  }

  List<DropdownMenuItem<int?>> _buildCategoryMenuItems() {
    final items = <DropdownMenuItem<int?>>[];
    int headerIndex = 0;

    for (final category in _categories) {
      // Add category group header (disabled) with unique negative value
      items.add(
        DropdownMenuItem<int?>(
          value: -(headerIndex++ + 1000),
          enabled: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              category.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      );

      // Add subcategories
      if (category.subcategories != null) {
        for (final subcategory in category.subcategories!) {
          items.add(
            DropdownMenuItem<int?>(
              value: subcategory.id,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.label,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(subcategory.name),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }

    return items;
  }
}
