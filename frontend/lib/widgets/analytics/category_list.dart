import 'package:flutter/material.dart';
import '../../models/analytics.dart';

class CategoryList extends StatelessWidget {
  final AnalyticsResponse analyticsData;
  final bool showSubcategories;
  final List<Color> colors;

  const CategoryList({
    super.key,
    required this.analyticsData,
    required this.showSubcategories,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final summary = analyticsData.summary;
    final breakdown = showSubcategories
        ? summary.subcategoryBreakdown
        : summary.categoryBreakdown;

    final spendingData = breakdown.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalSpending =
        spendingData.fold<double>(0, (sum, e) => sum + e.value);

    return Column(
      children: spendingData.asMap().entries.map((entry) {
        final index = entry.key;
        final id = entry.value.key;
        final amount = entry.value.value;
        final percentage =
            totalSpending > 0 ? (amount / totalSpending) * 100 : 0;
        final name = showSubcategories
            ? (analyticsData.subcategories[id]?.name ?? 'Unknown')
            : (analyticsData.categories[id]?.name ?? 'Unknown');

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
