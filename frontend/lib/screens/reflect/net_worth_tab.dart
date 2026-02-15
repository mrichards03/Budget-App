import 'package:flutter/material.dart';
import '../../models/analytics.dart';

class NetWorthTab extends StatelessWidget {
  final AnalyticsResponse? analyticsData;
  final VoidCallback onRefresh;

  const NetWorthTab({
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
              'Net Worth',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text('Coming soon - stacked chart showing assets vs debts'),
          ],
        ),
      ),
    );
  }
}
