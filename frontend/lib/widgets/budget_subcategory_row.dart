import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../utils/icon_helper.dart';
import 'editable_amount.dart';

class BudgetSubcategoryRow extends StatefulWidget {
  final SubcategoryBudget subcategoryBudget;
  final Function(SubcategoryBudget, double, String) onUpdate;
  final bool isWideScreen;

  const BudgetSubcategoryRow({
    super.key,
    required this.subcategoryBudget,
    required this.onUpdate,
    this.isWideScreen = false,
  });

  @override
  State<BudgetSubcategoryRow> createState() => _BudgetSubcategoryRowState();
}

class _BudgetSubcategoryRowState extends State<BudgetSubcategoryRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isWideScreen) {
      return _buildWideScreenRow();
    } else {
      return _buildNarrowScreenRow();
    }
  }

  Widget _buildWideScreenRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 12, 16, 12),
      child: Row(
        children: [
          Icon(
            IconHelper.getIconForSubcategory(widget.subcategoryBudget.subcategoryName),
            size: 20,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text(widget.subcategoryBudget.subcategoryName)),
          Expanded(
            child: Text(
              '\$${widget.subcategoryBudget.totalBalance.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: widget.subcategoryBudget.totalBalance < 0
                    ? Colors.red[700]
                    : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: EditableAmount(
              amount: widget.subcategoryBudget.monthlyAssigned,
              onSave: (newAmount) =>
                  widget.onUpdate(widget.subcategoryBudget, newAmount, 'assigned'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: EditableAmount(
              amount: widget.subcategoryBudget.monthlyTarget,
              onSave: (newAmount) =>
                  widget.onUpdate(widget.subcategoryBudget, newAmount, 'target'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              '\$${widget.subcategoryBudget.monthlyActivity.toStringAsFixed(2)}',
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
                  color: widget.subcategoryBudget.monthlyAvailable >= 0
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '\$${widget.subcategoryBudget.monthlyAvailable.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.subcategoryBudget.monthlyAvailable >= 0
                        ? Colors.green[700]
                        : Colors.red[700],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowScreenRow() {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 16, 12),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Icon(
                  IconHelper.getIconForSubcategory(widget.subcategoryBudget.subcategoryName),
                  size: 20,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.subcategoryBudget.subcategoryName)),
                Container(
                  constraints: const BoxConstraints(minWidth: 100),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.subcategoryBudget.monthlyAvailable >= 0
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '\$${widget.subcategoryBudget.monthlyAvailable.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.subcategoryBudget.monthlyAvailable >= 0
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            padding: const EdgeInsets.fromLTRB(72, 8, 16, 16),
            child: Column(
              children: [
                _buildExpandedRow(
                  'Total Balance',
                  '\$${widget.subcategoryBudget.totalBalance.toStringAsFixed(2)}',
                  isEditable: false,
                ),
                const SizedBox(height: 8),
                _buildExpandedRow(
                  'Monthly Assigned',
                  null,
                  isEditable: true,
                  editableAmount: widget.subcategoryBudget.monthlyAssigned,
                  onSave: (amount) => widget.onUpdate(widget.subcategoryBudget, amount, 'assigned'),
                ),
                const SizedBox(height: 8),
                _buildExpandedRow(
                  'Monthly Target',
                  null,
                  isEditable: true,
                  editableAmount: widget.subcategoryBudget.monthlyTarget,
                  onSave: (amount) => widget.onUpdate(widget.subcategoryBudget, amount, 'target'),
                ),
                const SizedBox(height: 8),
                _buildExpandedRow(
                  'Activity',
                  '\$${widget.subcategoryBudget.monthlyActivity.toStringAsFixed(2)}',
                  isEditable: false,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildExpandedRow(
    String label,
    String? value, {
    required bool isEditable,
    double? editableAmount,
    Function(double)? onSave,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: const Color.fromARGB(255, 211, 207, 207),
          ),
        ),
        if (isEditable && editableAmount != null && onSave != null)
          EditableAmount(
            amount: editableAmount,
            onSave: onSave,
            style: const TextStyle(fontWeight: FontWeight.w500),
          )
        else
          Text(
            value ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
