import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/transaction.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final transactionsData = await apiService.transactions.getTransactions();

      setState(() {
        _transactions =
            transactionsData.map((json) => Transaction.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 50, color: Colors.red),
                      const SizedBox(height: 20),
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadTransactions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox,
                              size: 100, color: Colors.grey),
                          const SizedBox(height: 20),
                          const Text('No transactions yet'),
                          const SizedBox(height: 10),
                          const Text(
                              'Connect your bank account to get started'),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadTransactions,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTransactions,
                      child: ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          return _buildTransactionCard(transaction);
                        },
                      ),
                    ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.amount < 0 ? Colors.red : Colors.green,
          child: Icon(
            transaction.amount < 0 ? Icons.arrow_upward : Icons.arrow_downward,
            color: Colors.white,
          ),
        ),
        title: Text(
          transaction.merchantName ?? transaction.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(transaction.date)),
            if (transaction.predictedCategory != null)
              Text(
                'Category: ${transaction.predictedCategory}',
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
          ],
        ),
        trailing: Text(
          currencyFormat.format(transaction.amount.abs()),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: transaction.amount < 0 ? Colors.red : Colors.green,
          ),
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.merchantName ?? transaction.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Amount: \$${transaction.amount}'),
            Text(
                'Date: ${DateFormat('MMM dd, yyyy').format(transaction.date)}'),
            if (transaction.category != null)
              Text('Plaid Category: ${transaction.category}'),
            if (transaction.predictedCategory != null)
              Text('Predicted Category: ${transaction.predictedCategory}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement manual categorization
                Navigator.pop(context);
              },
              child: const Text('Change Category'),
            ),
          ],
        ),
      ),
    );
  }
}
