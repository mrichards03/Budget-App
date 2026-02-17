import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/analytics.dart';
import '../../models/transaction.dart';

class SpendingTrendsTab extends StatefulWidget {
  final AnalyticsResponse? analyticsData;
  final VoidCallback onRefresh;

  const SpendingTrendsTab({
    super.key,
    required this.analyticsData,
    required this.onRefresh,
  });

  @override
  State<SpendingTrendsTab> createState() => _SpendingTrendsTabState();
}

class _SpendingTrendsTabState extends State<SpendingTrendsTab> {
  String _selectedView = 'daily'; // 'daily', 'weekly', 'monthly'
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    if (widget.analyticsData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildViewSelector(),
            const SizedBox(height: 24),
            _buildCategoryFilter(),
            const SizedBox(height: 24),
            _buildSpendingChart(),
            const SizedBox(height: 32),
            _buildMonthlyComparison(),
            const SizedBox(height: 32),
            _buildTopCategoriesTrends(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending Trends',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Visualize your spending patterns over time',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildViewSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
            value: 'daily',
            label: Text('Daily'),
            icon: Icon(Icons.calendar_today)),
        ButtonSegment(
            value: 'weekly',
            label: Text('Weekly'),
            icon: Icon(Icons.date_range)),
        ButtonSegment(
            value: 'monthly',
            label: Text('Monthly'),
            icon: Icon(Icons.calendar_month)),
      ],
      selected: {_selectedView},
      onSelectionChanged: (Set<String> selection) {
        setState(() {
          _selectedView = selection.first;
        });
      },
    );
  }

  Widget _buildCategoryFilter() {
    final categories = widget.analyticsData!.categories.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('All Categories'),
          selected: _selectedCategoryId == null,
          onSelected: (selected) {
            setState(() {
              _selectedCategoryId = null;
            });
          },
        ),
        ...categories.map((category) {
          return FilterChip(
            label: Text(category.name),
            selected: _selectedCategoryId == category.id,
            onSelected: (selected) {
              setState(() {
                _selectedCategoryId = selected ? category.id : null;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildSpendingChart() {
    final data = _getChartData();
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              'No spending data available for the selected period',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final maxY = data.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final minY = 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getChartTitle(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 5,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: _getBottomInterval(),
                        getTitlesWidget: (value, meta) {
                          return _getBottomTitle(value.toInt());
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey[300]!),
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  minY: minY,
                  maxY: maxY * 1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: data.length <= 31,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = _getDateForIndex(spot.x.toInt());
                          return LineTooltipItem(
                            '${_formatDate(date)}\n\$${spot.y.toStringAsFixed(2)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
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

  String _getChartTitle() {
    String view = _selectedView == 'daily'
        ? 'Daily'
        : _selectedView == 'weekly'
            ? 'Weekly'
            : 'Monthly';
    String category = _selectedCategoryId != null
        ? ' - ${widget.analyticsData!.categories[_selectedCategoryId]?.name}'
        : '';
    return '$view Spending$category';
  }

  List<FlSpot> _getChartData() {
    final transactions = _getFilteredTransactions();
    if (transactions.isEmpty) return [];

    // Group transactions by the selected view
    final Map<DateTime, double> groupedData = {};

    for (var transaction in transactions) {
      final date = _normalizeDate(transaction.effectiveDate);
      groupedData[date] = (groupedData[date] ?? 0) + transaction.amount.abs();
    }

    // Convert to FlSpot list
    final sortedDates = groupedData.keys.toList()..sort();
    if (sortedDates.isEmpty) return [];

    // Fill in missing dates with zero
    final firstDate = sortedDates.first;
    final lastDate = sortedDates.last;
    final allDates = <DateTime>[];

    DateTime current = firstDate;
    while (current.isBefore(lastDate) || current.isAtSameMomentAs(lastDate)) {
      allDates.add(current);
      current = _incrementDate(current);
    }

    return allDates.asMap().entries.map((entry) {
      final value = groupedData[entry.value] ?? 0.0;
      return FlSpot(entry.key.toDouble(), value);
    }).toList();
  }

  DateTime _normalizeDate(DateTime date) {
    if (_selectedView == 'daily') {
      return DateTime(date.year, date.month, date.day);
    } else if (_selectedView == 'weekly') {
      // Get Monday of the week
      final weekday = date.weekday;
      final monday = date.subtract(Duration(days: weekday - 1));
      return DateTime(monday.year, monday.month, monday.day);
    } else {
      // monthly
      return DateTime(date.year, date.month, 1);
    }
  }

  DateTime _incrementDate(DateTime date) {
    if (_selectedView == 'daily') {
      return date.add(const Duration(days: 1));
    } else if (_selectedView == 'weekly') {
      return date.add(const Duration(days: 7));
    } else {
      // monthly
      return DateTime(date.year, date.month + 1, 1);
    }
  }

  DateTime _getDateForIndex(int index) {
    final transactions = _getFilteredTransactions();
    if (transactions.isEmpty) return DateTime.now();

    final dates = transactions
        .map((t) => _normalizeDate(t.effectiveDate))
        .toSet()
        .toList()
      ..sort();

    if (index >= dates.length) return dates.last;

    final firstDate = dates.first;
    return _incrementDateByIndex(firstDate, index);
  }

  DateTime _incrementDateByIndex(DateTime start, int index) {
    if (_selectedView == 'daily') {
      return start.add(Duration(days: index));
    } else if (_selectedView == 'weekly') {
      return start.add(Duration(days: 7 * index));
    } else {
      return DateTime(start.year, start.month + index, 1);
    }
  }

  double _getBottomInterval() {
    final transactions = _getFilteredTransactions();
    if (transactions.isEmpty) return 1;

    final dates = transactions
        .map((t) => _normalizeDate(t.effectiveDate))
        .toSet()
        .toList();
    final count = dates.length;

    if (_selectedView == 'daily') {
      if (count <= 7) return 1;
      if (count <= 31) return 7;
      return 14;
    } else if (_selectedView == 'weekly') {
      return 1;
    } else {
      return 1;
    }
  }

  Widget _getBottomTitle(int index) {
    final date = _getDateForIndex(index);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        _formatDate(date),
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  String _formatDate(DateTime date) {
    if (_selectedView == 'daily') {
      return DateFormat('M/d').format(date);
    } else if (_selectedView == 'weekly') {
      return DateFormat('M/d').format(date);
    } else {
      return DateFormat('MMM').format(date);
    }
  }

  List<Transaction> _getFilteredTransactions() {
    var transactions = widget.analyticsData!.transactions
        .where((t) => t.amount < 0 && !t.isTransfer)
        .toList();

    if (_selectedCategoryId != null) {
      transactions = transactions.where((t) {
        if (t.subcategoryId == null) return false;
        final subcategory =
            widget.analyticsData!.subcategories[t.subcategoryId];
        return subcategory?.categoryId == _selectedCategoryId;
      }).toList();
    }

    return transactions;
  }

  Widget _buildMonthlyComparison() {
    final monthlyData = _getMonthlyComparisonData();
    if (monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Comparison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...monthlyData.entries.map((entry) {
              final isCurrentMonth = entry.key.year == DateTime.now().year &&
                  entry.key.month == DateTime.now().month;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        DateFormat('MMM yyyy').format(entry.key),
                        style: TextStyle(
                          fontWeight: isCurrentMonth
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: LinearProgressIndicator(
                        value:
                            entry.value / _getMaxMonthlySpending(monthlyData),
                        backgroundColor: Colors.grey[200],
                        minHeight: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '\$${entry.value.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.right,
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
  }

  Map<DateTime, double> _getMonthlyComparisonData() {
    final transactions = _getFilteredTransactions();
    final Map<DateTime, double> monthlyData = {};

    for (var transaction in transactions) {
      final monthKey = DateTime(
        transaction.effectiveDate.year,
        transaction.effectiveDate.month,
        1,
      );
      monthlyData[monthKey] =
          (monthlyData[monthKey] ?? 0) + transaction.amount.abs();
    }

    // Sort by date descending and take last 6 months
    final sortedEntries = monthlyData.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Map.fromEntries(sortedEntries.take(6).toList().reversed);
  }

  double _getMaxMonthlySpending(Map<DateTime, double> data) {
    if (data.isEmpty) return 1;
    return data.values.reduce((a, b) => a > b ? a : b);
  }

  Widget _buildTopCategoriesTrends() {
    final categoryTrends = _getCategoryTrends();
    if (categoryTrends.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Categories This Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryTrends.take(5).map((trend) {
              final category =
                  widget.analyticsData!.categories[trend.categoryId];
              if (category == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '\$${trend.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: trend.amount / categoryTrends.first.amount,
                      backgroundColor: Colors.grey[200],
                    ),
                    if (trend.percentChange != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${trend.percentChange! >= 0 ? '+' : ''}${trend.percentChange!.toStringAsFixed(1)}% vs last period',
                        style: TextStyle(
                          fontSize: 12,
                          color: trend.percentChange! >= 0
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<_CategoryTrend> _getCategoryTrends() {
    final transactions = widget.analyticsData!.transactions
        .where((t) => t.amount < 0 && !t.isTransfer)
        .toList();

    final Map<int, double> categorySpending = {};

    for (var transaction in transactions) {
      if (transaction.subcategoryId != null) {
        final subcategory =
            widget.analyticsData!.subcategories[transaction.subcategoryId];
        if (subcategory != null) {
          categorySpending[subcategory.categoryId] =
              (categorySpending[subcategory.categoryId] ?? 0) +
                  transaction.amount.abs();
        }
      }
    }

    final trends = categorySpending.entries
        .map((e) => _CategoryTrend(
              categoryId: e.key,
              amount: e.value,
              percentChange: null,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return trends;
  }
}

class _CategoryTrend {
  final int categoryId;
  final double amount;
  final double? percentChange;

  _CategoryTrend({
    required this.categoryId,
    required this.amount,
    this.percentChange,
  });
}
