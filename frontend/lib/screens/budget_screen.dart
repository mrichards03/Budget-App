import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/budget.dart';
import 'create_budget_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  Budget? _budget;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final budgetData = await apiService.getCurrentBudget();

      if (budgetData != null) {
        setState(() {
          _budget = Budget.fromJson(budgetData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load budget: $e')),
        );
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  void _showCreateBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: CreateBudgetScreen(
            onBudgetCreated: () {
              Navigator.of(context).pop();
              _loadBudget();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_budget == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              'No Budget Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a budget to start managing your finances',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showCreateBudgetDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Budget'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      );
    }

    final totalSpent = _budget!.subcategoryBudgets?.fold<double>(
          0,
          (sum, subcategory) => sum + (subcategory.currentSpending ?? 0),
        ) ??
        0;
    final totalAllocated = _budget!.totalAllocated ?? 0;
    final totalAvailable = totalAllocated - totalSpent;
    final percentSpent =
        (totalAllocated > 0) ? (totalSpent / totalAllocated) * 100 : 0;

    // Group subcategories by category
    final Map<String, List<SubcategoryBudget>> groupedSubcategories = {};
    if (_budget!.subcategoryBudgets != null) {
      for (var subcategory in _budget!.subcategoryBudgets!) {
        if (!groupedSubcategories.containsKey(subcategory.categoryName)) {
          groupedSubcategories[subcategory.categoryName] = [];
        }
        groupedSubcategories[subcategory.categoryName]!.add(subcategory);
      }
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadBudget,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _budget!.name,
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _budget!.endDate != null
                                    ? '${_budget!.startDate.month}/${_budget!.startDate.day}/${_budget!.startDate.year} - ${_budget!.endDate!.month}/${_budget!.endDate!.day}/${_budget!.endDate!.year}'
                                    : 'Started ${_budget!.startDate.month}/${_budget!.startDate.day}/${_budget!.startDate.year} (Ongoing)',
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
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadBudget,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Budget Overview Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            // Assigned in [Month]
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Assigned in ${_getMonthName(_budget!.startDate.month)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                Text(
                                  '\$${totalAllocated.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Activity
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Activity',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                Text(
                                  '-\$${totalSpent.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange[700],
                                      ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // Available
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Available',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '\$${totalAvailable.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: totalAvailable < 0
                                            ? Colors.red
                                            : totalAvailable == 0
                                                ? Colors.grey
                                                : Colors.green[700],
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Envelope Budgets Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  children: [
                    Text(
                      'Envelope Budgets',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    // Column Headers
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
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
                            flex: 2,
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
                            flex: 2,
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
                            flex: 2,
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
                  ],
                ),
              ),
            ),

            // Envelopes List (grouped by category)
            groupedSubcategories.isEmpty
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text('No envelopes defined'),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final categoryName =
                              groupedSubcategories.keys.elementAt(index);
                          final subcategories =
                              groupedSubcategories[categoryName]!;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    categoryName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...subcategories.map((subcategory) {
                                    final assigned =
                                        subcategory.allocatedAmount;
                                    final activity =
                                        subcategory.currentSpending ?? 0;
                                    final available = assigned - activity;

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              subcategory.subcategoryName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '\$${assigned.toStringAsFixed(2)}',
                                              textAlign: TextAlign.right,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '\$${activity.toStringAsFixed(2)}',
                                              textAlign: TextAlign.right,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: activity > 0
                                                        ? Colors.orange[700]
                                                        : null,
                                                  ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '\$${available.toStringAsFixed(2)}',
                                              textAlign: TextAlign.right,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: available < 0
                                                        ? Colors.red
                                                        : available == 0
                                                            ? Colors.grey
                                                            : Colors.green[700],
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: groupedSubcategories.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
