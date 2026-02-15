import 'package:flutter/material.dart';
import '../models/budget.dart';
import 'budget_subcategory_row.dart';

class BudgetCategoryGroup extends StatelessWidget {
  final String categoryName;
  final List<SubcategoryBudget> subcategories;
  final Function(SubcategoryBudget, double) onAmountUpdate;

  const BudgetCategoryGroup({
    super.key,
    required this.categoryName,
    required this.subcategories,
    required this.onAmountUpdate,
  });

  double get _totalAssigned =>
      subcategories.fold(0.0, (sum, sb) => sum + sb.allocatedAmount);

  double get _totalActivity =>
      subcategories.fold(0.0, (sum, sb) => sum + (sb.currentSpending ?? 0.0));

  double get _totalAvailable => _totalAssigned - _totalActivity;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      leading: const Icon(Icons.folder, color: Colors.blue),
      title: Row(
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
              '\$${_totalAssigned.toStringAsFixed(2)}',
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
      ),
      children: subcategories
          .map((sb) => BudgetSubcategoryRow(
                subcategoryBudget: sb,
                onAmountUpdate: onAmountUpdate,
              ))
          .toList(),
    );
  }
}
