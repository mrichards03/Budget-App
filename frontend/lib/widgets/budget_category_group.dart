import 'package:flutter/material.dart';
import '../models/budget.dart';
import 'budget_subcategory_row.dart';

class BudgetCategoryGroup extends StatelessWidget {
  final String categoryName;
  final List<SubcategoryBudget> subcategories;
  final Function(SubcategoryBudget, double, String) onUpdate;
  final bool isWideScreen;

  const BudgetCategoryGroup({
    super.key,
    required this.categoryName,
    required this.subcategories,
    required this.onUpdate,
    this.isWideScreen = false,
  });

  double get _totalBalance =>
      subcategories.fold(0.0, (sum, sb) => sum + sb.totalBalance);

  double get _totalAssigned =>
      subcategories.fold(0.0, (sum, sb) => sum + sb.monthlyAssigned);

  double get _totalTarget =>
      subcategories.fold(0.0, (sum, sb) => sum + sb.monthlyTarget);

  double get _totalActivity =>
      subcategories.fold(0.0, (sum, sb) => sum + sb.monthlyActivity);

  double get _totalAvailable =>
      subcategories.fold(0.0, (sum, sb) => sum + sb.monthlyAvailable);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      controlAffinity: ListTileControlAffinity.leading,
      title: isWideScreen ? _buildWideScreenTitle() : _buildNarrowScreenTitle(),
      children: subcategories
          .map(
            (sb) => BudgetSubcategoryRow(
              subcategoryBudget: sb,
              onUpdate: onUpdate,
              isWideScreen: isWideScreen,
            ),
          )
          .toList(),
    );
  }

  Widget _buildWideScreenTitle() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            categoryName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            '\$${_totalBalance.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _totalBalance < 0 ? Colors.red : Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            '\$${_totalAssigned.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            '\$${_totalTarget.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            '\$${_totalActivity.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            '\$${_totalAvailable.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _totalAvailable >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowScreenTitle() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            categoryName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            '\$${_totalAvailable.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _totalAvailable >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}
