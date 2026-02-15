import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../widgets/budget_summary_card.dart';
import '../widgets/budget_category_group.dart';
import '../widgets/create_budget_dialog.dart';
import '../widgets/empty_state_widget.dart';

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
    CreateBudgetDialog.show(
      context,
      onCreateBudget: _createNewBudget,
    );
  }

  Map<String, List<SubcategoryBudget>> _groupByCategory() {
    if (_budget?.subcategoryBudgets == null) return {};

    final Map<String, List<SubcategoryBudget>> grouped = {};
    for (var sb in _budget!.subcategoryBudgets!) {
      grouped.putIfAbsent(sb.categoryName, () => []).add(sb);
    }
    return grouped;
  }

  double _calculateTotalAssigned() =>
      _budget?.subcategoryBudgets
          ?.fold(0.0, (sum, sb) => sum! + sb.allocatedAmount) ??
      0.0;

  double _calculateTotalActivity() =>
      _budget?.subcategoryBudgets
          ?.fold(0.0, (sum, sb) => sum! + (sb.currentSpending ?? 0.0)) ??
      0.0;

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
        body: EmptyStateWidget(
          icon: Icons.account_balance_wallet,
          title: 'No budget found',
          subtitle: 'Create a budget to start tracking your finances',
          actionLabel: 'Create New Budget',
          onAction: _showCreateBudgetDialog,
        ),
      );
    }

    return _buildBudgetView();
  }

  Widget _buildBudgetView() {
    final groupedCategories = _groupByCategory();
    final totalAssigned = _calculateTotalAssigned();
    final totalActivity = _calculateTotalActivity();
    final totalAvailable = totalAssigned - totalActivity;
    final unassigned = _totalBalance - totalAssigned;

    return Scaffold(
      body: Column(
        children: [
          BudgetSummaryCard(
            budgetName: _budget!.name,
            totalAssigned: totalAssigned,
            totalActivity: totalActivity,
            totalAvailable: totalAvailable,
            totalBalance: _totalBalance,
            unassigned: unassigned,
          ),
          _buildCategoryHeaders(),
          Expanded(
            child: ListView.builder(
              itemCount: groupedCategories.length,
              itemBuilder: (context, index) {
                final categoryName = groupedCategories.keys.elementAt(index);
                final subcategories = groupedCategories[categoryName]!;
                return BudgetCategoryGroup(
                  categoryName: categoryName,
                  subcategories: subcategories,
                  onAmountUpdate: _updateSubcategoryAmount,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeaders() {
    return Container(
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
    );
  }
}
