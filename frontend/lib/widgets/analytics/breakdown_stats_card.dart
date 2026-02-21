import 'package:flutter/material.dart';
import '../../models/analytics.dart';
import 'stat_item.dart';

class BreakdownStatsCard extends StatelessWidget {
  final AnalyticsResponse analyticsData;
  final bool showSubcategories;
  final DateTime? startDate;
  final DateTime? endDate;

  const BreakdownStatsCard({
    super.key,
    required this.analyticsData,
    required this.showSubcategories,
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final summary = analyticsData.summary;
    final totalExpenses = summary.totalSpending.abs();
    final days = endDate != null && startDate != null
        ? endDate!.difference(startDate!).inDays
        : 30;
    final avgDaily = days > 0 ? totalExpenses / days : 0;

    // Find most frequent category
    final breakdown = showSubcategories
        ? summary.subcategoryBreakdown
        : summary.categoryBreakdown;
    final spendingData = breakdown.entries.where((e) => e.value < 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final mostFrequentId =
        spendingData.isNotEmpty ? spendingData.first.key : null;
    final mostFrequentName = mostFrequentId != null
        ? (showSubcategories
            ? (analyticsData.subcategories[mostFrequentId]?.name ?? 'Unknown')
            : (analyticsData.categories[mostFrequentId]?.name ?? 'Unknown'))
        : 'N/A';

    final largestOutflow =
        spendingData.isNotEmpty ? spendingData.first.value : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatItem(
                title: 'Average Monthly Spending',
                value: '\$${totalExpenses.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatItem(
                title: 'Average Daily Spending',
                value: '\$${avgDaily.toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatItem(
                title: 'Most Frequent Category',
                value: mostFrequentName,
                subtitle: '1 transaction',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatItem(
                title: 'Largest Outflow',
                value: mostFrequentName.toLowerCase(),
                subtitle: '\$${largestOutflow.toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
