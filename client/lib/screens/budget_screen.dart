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
  bool _isLoading = true;
  String? _error;
  double _totalBalance = 0.0;

  // Track selected month/year for navigation
  int? _selectedYear;
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    // Initialize to current month
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Load budget for selected month/year
      final budgetData = await apiService.budgets.getBudgetByMonth(
        _selectedYear!,
        _selectedMonth!,
      );

      // Load categories and total balance in parallel
      final balance = await apiService.accounts.getTotalBalance();

      setState(() {
        if (budgetData != null) {
          _budget = Budget.fromJson(budgetData);
        }
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

  void _navigateMonth(int delta) {
    setState(() {
      int newMonth = _selectedMonth! + delta;
      int newYear = _selectedYear!;

      if (newMonth > 12) {
        newMonth = 1;
        newYear++;
      } else if (newMonth < 1) {
        newMonth = 12;
        newYear--;
      }

      _selectedMonth = newMonth;
      _selectedYear = newYear;
    });

    _loadBudget();
  }

  bool _canNavigateForward() {
    // Can only navigate up to 1 month ahead of current date
    final now = DateTime.now();
    final selected = DateTime(_selectedYear!, _selectedMonth!);
    final maxAllowed = DateTime(now.year, now.month + 1);
    return selected.isBefore(maxAllowed);
  }

  Future<void> _createNewBudget(String budgetName) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final budgetData = await apiService.budgets.createBudgetWithAllCategories(
        budgetName,
      );
      setState(() {
        _budget = Budget.fromJson(budgetData);
      });
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create budget: $e')));
      }
    }
  }

  Future<void> _updateSubcategoryBudget(
    SubcategoryBudget subcategoryBudget,
    double newValue,
    String field,
  ) async {
    if (_budget == null || subcategoryBudget.id == null) return;

    final updatedSubcategoryBudgets = _budget!.subcategoryBudgets?.map((sb) {
      if (sb.id == subcategoryBudget.id) {
        if (field == 'assigned') {
          return sb.copyWith(monthlyAssigned: newValue);
        } else {
          final newAvailable = newValue - sb.monthlyActivity;
          return sb.copyWith(
            monthlyTarget: newValue,
            monthlyAvailable: newAvailable,
          );
        }
      }
      return sb;
    }).toList();

    setState(() {
      _budget = _budget!.copyWith(
        subcategoryBudgets: updatedSubcategoryBudgets,
      );
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      if (field == 'assigned') {
        await apiService.budgets.updateSubcategoryBudget(
          budgetId: _budget!.id!,
          subcategoryBudgetId: subcategoryBudget.id!,
          monthlyAssigned: newValue,
        );
      } else {
        await apiService.budgets.updateSubcategoryBudget(
          budgetId: _budget!.id!,
          subcategoryBudgetId: subcategoryBudget.id!,
          monthlyTarget: newValue,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  void _showCreateBudgetDialog() {
    CreateBudgetDialog.show(context, onCreateBudget: _createNewBudget);
  }

  Map<String, List<SubcategoryBudget>> _groupByCategory() {
    if (_budget?.subcategoryBudgets == null) return {};

    final Map<String, List<SubcategoryBudget>> grouped = {};
    for (var sb in _budget!.subcategoryBudgets!) {
      if (sb.categoryName == "Transfers" || sb.categoryName == "Income") {
        continue;
      }
      grouped.putIfAbsent(sb.categoryName, () => []).add(sb);
    }
    return grouped;
  }

  double _calculateTotalAssigned() =>
      _budget?.subcategoryBudgets?.fold(
        0.0,
        (sum, sb) => sum! + sb.monthlyAssigned,
      ) ??
      0.0;

  double _calculateTotalActivity() =>
      _budget?.subcategoryBudgets
          ?.fold(0.0, (sum, sb) => sum! + sb.monthlyActivity) ??
      0.0;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
    final unassigned = _totalBalance - totalAssigned;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;

    return Scaffold(
      body: Column(
        children: [
          BudgetSummaryCard(
            budgetName: _budget!.name,
            unassigned: unassigned,
            // Add month navigation
            leadingWidget: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _navigateMonth(-1),
              tooltip: 'Previous month',
            ),
            trailingWidget: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _canNavigateForward() ? () => _navigateMonth(1) : null,
              tooltip: 'Next month',
            ),
          ),
          _buildCategoryHeaders(isWideScreen),
          Expanded(
            child: ListView.builder(
              itemCount:
                  groupedCategories.length,
              itemBuilder: (context, index) {
                final categoryName = groupedCategories.keys.elementAt(index);
                final subcategories = groupedCategories[categoryName]!;
                return BudgetCategoryGroup(
                  categoryName: categoryName,
                  subcategories: subcategories,
                  onUpdate: _updateSubcategoryBudget,
                  isWideScreen: isWideScreen,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeaders(bool isWideScreen) {
    if (isWideScreen) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                'TOTAL BALANCE',
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
                'TARGET',
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
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
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
}
