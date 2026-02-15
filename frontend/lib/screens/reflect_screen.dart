import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class ReflectScreen extends StatefulWidget {
  const ReflectScreen({super.key});

  @override
  State<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends State<ReflectScreen> {
  Map<String, dynamic>? _spendingBreakdown;
  Map<String, dynamic>? _incomeVsSpending;
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      final spending = await apiService.getSpendingBreakdown(
        startDate: _startDate,
        endDate: _endDate,
      );
      final income = await apiService.getIncomeVsSpending(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _spendingBreakdown = spending;
        _incomeVsSpending = income;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load analytics: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now(),
        end: _endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
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
                              Text(
                                'Reflect',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: _selectDateRange,
                                    icon: const Icon(Icons.date_range),
                                    label: Text(
                                      _startDate != null && _endDate != null
                                          ? '${_startDate!.month}/${_startDate!.day} - ${_endDate!.month}/${_endDate!.day}'
                                          : 'Select Range',
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: _loadData,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Income vs Spending Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Income vs Spending',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      title: 'Total Income',
                                      amount:
                                          _incomeVsSpending?['total_income'] ??
                                              0.0,
                                      color: Colors.green,
                                      icon: Icons.arrow_downward,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _StatCard(
                                      title: 'Total Spending',
                                      amount: (_incomeVsSpending?[
                                                  'total_spending'] ??
                                              0.0)
                                          .abs(),
                                      color: Colors.red,
                                      icon: Icons.arrow_upward,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _StatCard(
                                title: 'Net',
                                amount: _incomeVsSpending?['net'] ?? 0.0,
                                color: (_incomeVsSpending?['net'] ?? 0.0) >= 0
                                    ? Colors.green
                                    : Colors.red,
                                icon: Icons.account_balance,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Spending Breakdown
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Text(
                        'Spending Breakdown',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    sliver: _spendingBreakdown == null ||
                            _spendingBreakdown!['categories'] == null ||
                            (_spendingBreakdown!['categories'] as Map).isEmpty
                        ? const SliverToBoxAdapter(
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Center(
                                  child:
                                      Text('No spending data for this period'),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final categories =
                                    _spendingBreakdown!['categories'] as Map;
                                final category =
                                    categories.keys.elementAt(index);
                                final amount = (categories[category] as num)
                                    .toDouble()
                                    .abs();
                                final total =
                                    _spendingBreakdown!['total_spending']
                                        as num;
                                final percentage = total != 0
                                    ? (amount / total.abs()) * 100
                                    : 0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              category,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            Text(
                                              '\$${amount.toStringAsFixed(2)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: percentage / 100,
                                            minHeight: 8,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${percentage.toStringAsFixed(1)}% of total spending',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount:
                                  (_spendingBreakdown!['categories'] as Map)
                                      .length,
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${amount.abs().toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
