import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/analytics.dart';
import '../models/transaction.dart' as models;

class ReflectScreen extends StatefulWidget {
  const ReflectScreen({super.key});

  @override
  State<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends State<ReflectScreen> {
  AnalyticsResponse? _analyticsData;
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;
  int _hoveredCategoryIndex = -1;
  int _hoveredSubcategoryIndex = -1;

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

      final data = await apiService.analytics.getAnalyticsData(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _analyticsData = AnalyticsResponse.fromJson(data);
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
    final summary = _analyticsData?.summary;

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

                  // Summary Stats Cards
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
                                'Summary',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 24),

                              // Total Income and Spending
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      title: 'Total Income',
                                      amount: (summary?.totalIncome ?? 0.0).abs(),
                                      color: Colors.green,
                                      icon: Icons.arrow_downward,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _StatCard(
                                      title: 'Total Spending',
                                      amount: summary?.totalSpending ?? 0.0,
                                      color: Colors.red,
                                      icon: Icons.arrow_upward,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Net
                              _StatCard(
                                title: 'Net',
                                amount: summary?.net ?? 0.0,
                                color: (summary?.net ?? 0.0) >= 0
                                    ? Colors.green
                                    : Colors.red,
                                icon: Icons.account_balance,
                              ),

                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 24),

                              // Averages
                              Text(
                                'Averages',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      title: 'Monthly Spending',
                                      amount: summary?.monthlyAverageSpending ?? 0.0,
                                      color: Colors.orange,
                                      icon: Icons.calendar_month,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _StatCard(
                                      title: 'Daily Spending',
                                      amount: summary?.dailyAverageSpending ?? 0.0,
                                      color: Colors.purple,
                                      icon: Icons.today,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Category Pie Chart
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
                                'Spending by Category',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 24),
                              _buildCategoryPieChart(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Subcategory Pie Chart
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
                                'Spending by Subcategory',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 24),
                              _buildSubcategoryPieChart(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Transaction List for Hovered Category
                  if (_hoveredCategoryIndex >= 0)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: _buildTransactionsList(
                                _hoveredCategoryIndex, true),
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    final summary = _analyticsData?.summary;
    if (summary == null || summary.categoryBreakdown.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No spending data for this period'),
        ),
      );
    }

    // Filter to only spending (positive amounts per Plaid convention)
    final spendingData =
        summary.categoryBreakdown.entries.where((e) => e.value > 0).toList();

    if (spendingData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No spending data for this period'),
        ),
      );
    }

    final totalSpending =
        spendingData.fold<double>(0, (sum, e) => sum + e.value);
    final colors = _generateColors(spendingData.length);

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: spendingData.asMap().entries.map((entry) {
                final index = entry.key;
                final subcategoryId = entry.value.key;
                final amount = entry.value.value;
                final percentage = (amount / totalSpending) * 100;
                final isHovered = _hoveredCategoryIndex == index;

                return PieChartSectionData(
                  value: amount,
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: isHovered ? 110 : 100,
                  titleStyle: TextStyle(
                    fontSize: isHovered ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  color: colors[index],
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _hoveredCategoryIndex = -1;
                      return;
                    }
                    _hoveredCategoryIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: spendingData.asMap().entries.map((entry) {
            final index = entry.key;
            final categoryId = entry.value.key;
            final amount = entry.value.value;
            final categoryName =
                _analyticsData?.categories[categoryId]?.name ?? 'Unknown';

            return InkWell(
              onTap: () {
                setState(() {
                  _hoveredCategoryIndex =
                      _hoveredCategoryIndex == index ? -1 : index;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors[index],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$categoryName (\$${amount.toStringAsFixed(2)})',
                    style: TextStyle(
                      fontWeight: _hoveredCategoryIndex == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubcategoryPieChart() {
    final summary = _analyticsData?.summary;
    if (summary == null || summary.subcategoryBreakdown.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No spending data for this period'),
        ),
      );
    }

    // Filter to only spending (positive amounts per Plaid convention)
    final spendingData =
        summary.subcategoryBreakdown.entries.where((e) => e.value > 0).toList();

    if (spendingData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No spending data for this period'),
        ),
      );
    }

    final totalSpending =
        spendingData.fold<double>(0, (sum, e) => sum + e.value);
    final colors = _generateColors(spendingData.length);

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: spendingData.asMap().entries.map((entry) {
                final index = entry.key;
                final subcategoryId = entry.value.key;
                final amount = entry.value.value;
                final percentage = (amount / totalSpending) * 100;
                final isHovered = _hoveredSubcategoryIndex == index;

                return PieChartSectionData(
                  value: amount,
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: isHovered ? 110 : 100,
                  titleStyle: TextStyle(
                    fontSize: isHovered ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  color: colors[index],
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _hoveredSubcategoryIndex = -1;
                      return;
                    }
                    _hoveredSubcategoryIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: spendingData.asMap().entries.map((entry) {
            final index = entry.key;
            final subcategoryId = entry.value.key;
            final amount = entry.value.value;
            final subcategoryName =
                _analyticsData?.subcategories[subcategoryId]?.name ?? 'Unknown';

            return InkWell(
              onTap: () {
                setState(() {
                  _hoveredSubcategoryIndex =
                      _hoveredSubcategoryIndex == index ? -1 : index;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors[index],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$subcategoryName (\$${amount.toStringAsFixed(2)})',
                    style: TextStyle(
                      fontWeight: _hoveredSubcategoryIndex == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(int index, bool isCategory) {
    if (_analyticsData == null) return const SizedBox.shrink();

    final summary = _analyticsData!.summary;
    final spendingData = isCategory
        ? summary.categoryBreakdown.entries.where((e) => e.value < 0).toList()
        : summary.subcategoryBreakdown.entries
            .where((e) => e.value < 0)
            .toList();

    if (index >= spendingData.length) return const SizedBox.shrink();

    final id = spendingData[index].key;
    final transactions = isCategory
        ? _analyticsData!.getTransactionsForCategory(id)
        : _analyticsData!.getTransactionsForSubcategory(id);

    final name = isCategory
        ? _analyticsData!.categories[id]?.name ?? 'Unknown'
        : _analyticsData!.subcategories[id]?.name ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions in $name',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ...transactions.map((transaction) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.displayName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${transaction.effectiveDate.month}/${transaction.effectiveDate.day}/${transaction.effectiveDate.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${transaction.amount.abs().toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  List<Color> _generateColors(int count) {
    final baseColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];

    if (count <= baseColors.length) {
      return baseColors.sublist(0, count);
    }

    // Generate more colors if needed
    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      final hue = (i * 360 / count) % 360;
      colors.add(HSLColor.fromAHSL(1, hue, 0.7, 0.5).toColor());
    }
    return colors;
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
