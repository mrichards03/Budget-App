import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../utils/icon_helper.dart';
import 'editable_amount.dart';

class BudgetSubcategoryRow extends StatelessWidget {
  final SubcategoryBudget subcategoryBudget;
  final Function(SubcategoryBudget, double) onAmountUpdate;

  const BudgetSubcategoryRow({
    super.key,
    required this.subcategoryBudget,
    required this.onAmountUpdate,
  });

  double get _available =>
      subcategoryBudget.allocatedAmount -
      (subcategoryBudget.currentSpending ?? 0.0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 12, 16, 12),
      child: Row(
        children: [
          Icon(
            IconHelper.getIconForSubcategory(subcategoryBudget.subcategoryName),
            size: 20,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(subcategoryBudget.subcategoryName),
          ),
          Expanded(
            child: EditableAmount(
              amount: subcategoryBudget.allocatedAmount,
              onSave: (newAmount) =>
                  onAmountUpdate(subcategoryBudget, newAmount),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '\$${(subcategoryBudget.currentSpending ?? 0.0).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 100),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: _available >= 0
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '\$${_available.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        _available >= 0 ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
