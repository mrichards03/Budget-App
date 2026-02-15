import 'package:flutter/material.dart';
import '../../models/analytics.dart';

class SpendingTrendsTab extends StatelessWidget {
  final AnalyticsResponse? analyticsData;
  final VoidCallback onRefresh;

  const SpendingTrendsTab({
    super.key,
    required this.analyticsData,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Trends',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text('Coming soon - bar chart showing spending over time'),
          ],
        ),
      ),
    );
  }
}
