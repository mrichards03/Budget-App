import 'package:flutter/material.dart';
import '../../models/analytics.dart';
import '../../widgets/analytics/category_pie_chart.dart';
import '../../widgets/analytics/category_list.dart';
import '../../widgets/analytics/breakdown_stats_card.dart';

class SpendingBreakdownTab extends StatefulWidget {
  final AnalyticsResponse? analyticsData;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onRefresh;
  final VoidCallback onSelectDateRange;

  const SpendingBreakdownTab({
    super.key,
    required this.analyticsData,
    required this.startDate,
    required this.endDate,
    required this.onRefresh,
    required this.onSelectDateRange,
  });

  @override
  State<SpendingBreakdownTab> createState() => _SpendingBreakdownTabState();
}

class _SpendingBreakdownTabState extends State<SpendingBreakdownTab> {
  bool _showSubcategories = true;

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

    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      final hue = (i * 360 / count) % 360;
      colors.add(HSLColor.fromAHSL(1, hue, 0.7, 0.5).toColor());
    }
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.analyticsData?.summary;

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date selector
            Row(
              children: [
                InkWell(
                  onTap: widget.onSelectDateRange,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.startDate?.month}/${widget.startDate?.year ?? ''}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: widget.onRefresh,
                  child: const Text('This Month'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Total Spending
            Text(
              'Total Spending',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            Text(
              '\$${(summary?.totalSpending.abs() ?? 0).toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),

            // Pie Chart and Legend
            if (widget.analyticsData != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Pie chart
                  Expanded(
                    flex: 2,
                    child: _buildPieChart(),
                  ),
                  const SizedBox(width: 24),
                  // Right side - Categories/Groups toggle and list
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Toggle
                        Container(
                            child: SegmentedButton(
                              segments: const [
                                ButtonSegment(
                                    value: true, label: Text("Categories")),
                                ButtonSegment(
                                    value: false, label: Text("Groups"))
                              ],
                              selected: {_showSubcategories},
                              onSelectionChanged: (show) {
                                setState(() {
                                  _showSubcategories = show.first;                                  
                                });
                              },
                            )),
                        const SizedBox(height: 16),
                        Text(
                          'Categories',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Total Spending',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        CategoryList(
                          analyticsData: widget.analyticsData!,
                          showSubcategories: _showSubcategories,
                          colors: _generateColors(_getBreakdownLength()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            // Stats at bottom
            if (widget.analyticsData != null)
              BreakdownStatsCard(
                analyticsData: widget.analyticsData!,
                showSubcategories: _showSubcategories,
                startDate: widget.startDate,
                endDate: widget.endDate,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final summary = widget.analyticsData!.summary;
    final breakdown = _showSubcategories
        ? summary.subcategoryBreakdown
        : summary.categoryBreakdown;

    final spendingData = breakdown.entries.where((e) => e.value < 0).toList();
    final totalSpending =
        spendingData.fold<double>(0, (sum, e) => sum + e.value.abs());

    return CategoryPieChart(
      breakdown: breakdown,
      colors: _generateColors(spendingData.length),
      totalSpending: totalSpending,
    );
  }

  int _getBreakdownLength() {
    final summary = widget.analyticsData!.summary;
    final breakdown = _showSubcategories
        ? summary.subcategoryBreakdown
        : summary.categoryBreakdown;
    return breakdown.entries.where((e) => e.value < 0).length;
  }
}
