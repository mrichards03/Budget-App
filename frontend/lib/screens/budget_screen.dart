import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../widgets/editable_amount.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  Budget? _budget;
  List<Category>? _categories;
  bool _isLoading = true;
  String? _error;
  double _totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Load budget and categories in parallel
      final results = await Future.wait([
        apiService.budgets.getCurrentBudget(),
        apiService.categories.getCategories(),
        apiService.accounts.getTotalBalance(),
      ]);

      final budgetData = results[0] as Map<String, dynamic>?;
      final categoriesData = results[1] as List<dynamic>;
      final balance = results[2] as double;

      setState(() {
        if (budgetData != null) {
          _budget = Budget.fromJson(budgetData);
        }
        _categories = categoriesData.map((c) => Category.fromJson(c)).toList();
        _totalBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewBudget(String budgetName) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final budgetData =
          await apiService.budgets.createBudgetWithAllCategories(budgetName);
      setState(() {
        _budget = Budget.fromJson(budgetData);
      });
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create budget: $e')),
        );
      }
    }
  }

  Future<void> _updateSubcategoryAmount(
      SubcategoryBudget subcategoryBudget, double newAmount) async {
    if (_budget == null || subcategoryBudget.id == null) return;

    // Update in memory immediately
    final updatedSubcategoryBudgets = _budget!.subcategoryBudgets?.map((sb) {
      if (sb.id == subcategoryBudget.id) {
        return sb.copyWith(allocatedAmount: newAmount);
      }
      return sb;
    }).toList();

    setState(() {
      _budget =
          _budget!.copyWith(subcategoryBudgets: updatedSubcategoryBudgets);
    });

    // Update in background
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.budgets.updateSubcategoryBudget(
        budgetId: _budget!.id!,
        subcategoryBudgetId: subcategoryBudget.id!,
        allocatedAmount: newAmount,
      );
    } catch (e) {
      // If update fails, show error but keep the optimistic update
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  void _showCreateBudgetDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Budget',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Budget Name',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isNotEmpty) {
                        _createNewBudget(name);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('Create Plan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<SubcategoryBudget>> _groupByCategory() {
    if (_budget?.subcategoryBudgets == null) return {};

    final Map<String, List<SubcategoryBudget>> grouped = {};
    for (var sb in _budget!.subcategoryBudgets!) {
      if (!grouped.containsKey(sb.categoryName)) {
        grouped[sb.categoryName] = [];
      }
      grouped[sb.categoryName]!.add(sb);
    }
    return grouped;
  }

  double _getCategoryAssigned(List<SubcategoryBudget> subcategories) {
    return subcategories.fold(0.0, (sum, sb) => sum + sb.allocatedAmount);
  }

  double _getCategoryActivity(List<SubcategoryBudget> subcategories) {
    return subcategories.fold(
        0.0, (sum, sb) => sum + (sb.currentSpending ?? 0.0));
  }

  double _getCategoryAvailable(List<SubcategoryBudget> subcategories) {
    final assigned = _getCategoryAssigned(subcategories);
    final activity = _getCategoryActivity(subcategories);
    return assigned - activity;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadBudget,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_budget == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No budget found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a budget to start tracking your finances',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showCreateBudgetDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create New Budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate totals
    final groupedCategories = _groupByCategory();
    final totalAssigned = _budget!.subcategoryBudgets
            ?.fold(0.0, (sum, sb) => sum + sb.allocatedAmount) ??
        0.0;
    final totalActivity = _budget!.subcategoryBudgets
            ?.fold(0.0, (sum, sb) => sum + (sb.currentSpending ?? 0.0)) ??
        0.0;
    final totalAvailable = totalAssigned - totalActivity;
    final unassigned = _totalBalance - totalAssigned;

    return Scaffold(
      body: Column(
        children: [
          // Top summary card
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _budget!.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Assigned',
                        totalAssigned,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Activity',
                        totalActivity,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Available',
                        totalAvailable,
                        totalAvailable >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Total Money',
                        _totalBalance,
                        Colors.purple,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Unassigned',
                        unassigned,
                        unassigned >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Category headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[200],
            child: Row(
              children: [
                const SizedBox(width: 40),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'CATEGORY',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'ASSIGNED',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'ACTIVITY',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'AVAILABLE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Category list
          Expanded(
            child: ListView.builder(
              itemCount: groupedCategories.length,
              itemBuilder: (context, index) {
                final categoryName = groupedCategories.keys.elementAt(index);
                final subcategories = groupedCategories[categoryName]!;
                return _buildCategoryGroup(categoryName, subcategories);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGroup(
      String categoryName, List<SubcategoryBudget> subcategories) {
    return ExpansionTile(
      initiallyExpanded: true,
      leading: const Icon(Icons.folder, color: Colors.blue),
      title: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              categoryName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              '\$${_getCategoryAssigned(subcategories).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              '\$${_getCategoryActivity(subcategories).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              '\$${_getCategoryAvailable(subcategories).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getCategoryAvailable(subcategories) >= 0
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
        ],
      ),
      children: subcategories.map((sb) => _buildSubcategoryRow(sb)).toList(),
    );
  }

  Widget _buildSubcategoryRow(SubcategoryBudget subcategoryBudget) {
    final available = subcategoryBudget.allocatedAmount -
        (subcategoryBudget.currentSpending ?? 0.0);

    return Container(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 12, 16, 12),
        child: Row(
          children: [
            Icon(
              _getIconForSubcategory(subcategoryBudget.subcategoryName),
              size: 20,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(subcategoryBudget.subcategoryName),
            ),
            Expanded(
              child: EditableAmount(
                amount: subcategoryBudget.allocatedAmount,
                onSave: (newAmount) =>
                    _updateSubcategoryAmount(subcategoryBudget, newAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '\$${(subcategoryBudget.currentSpending ?? 0.0).toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 100),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: available >= 0
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '\$${available.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          available >= 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForSubcategory(String subcategoryName) {
    final name = subcategoryName.toLowerCase();
    if (name.contains('rent') || name.contains('mortgage')) return Icons.home;
    if (name.contains('phone')) return Icons.phone;
    if (name.contains('internet')) return Icons.wifi;
    if (name.contains('utilit')) return Icons.bolt;
    if (name.contains('grocer')) return Icons.shopping_cart;
    if (name.contains('transport')) return Icons.directions_car;
    if (name.contains('medical')) return Icons.medical_services;
    if (name.contains('emergency')) return Icons.emergency;
    if (name.contains('dining')) return Icons.restaurant;
    if (name.contains('entertainment')) return Icons.movie;
    if (name.contains('vacation')) return Icons.flight;
    if (name.contains('subscription')) return Icons.sync;
    return Icons.category;
  }
}
