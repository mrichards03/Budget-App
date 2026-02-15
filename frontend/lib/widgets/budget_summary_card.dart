import 'package:flutter/material.dart';

class BudgetSummaryCard extends StatelessWidget {
  final String budgetName;
  final double totalAssigned;
  final double totalActivity;
  final double totalAvailable;
  final double totalBalance;
  final double unassigned;
  final Widget? leadingWidget;
  final Widget? trailingWidget;

  const BudgetSummaryCard({
    super.key,
    required this.budgetName,
    required this.totalAssigned,
    required this.totalActivity,
    required this.totalAvailable,
    required this.totalBalance,
    required this.unassigned,
    this.leadingWidget,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leadingWidget != null) leadingWidget!,
              Expanded(
                child: Text(
                  budgetName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              if (trailingWidget != null) trailingWidget!,
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Assigned',
                  amount: totalAssigned,
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Activity',
                  amount: totalActivity,
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Available',
                  amount: totalAvailable,
                  color: totalAvailable >= 0 ? Colors.green : Colors.red,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Total Money',
                  amount: totalBalance,
                  color: Colors.purple,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Unassigned',
                  amount: unassigned,
                  color: unassigned >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
