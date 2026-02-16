import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class TransactionCategoryField extends StatelessWidget {
  final Transaction transaction;
  final List<Category> categories;
  final bool isEditing;
  final VoidCallback onTap;
  final Function(int subcategoryId) onCategorySelected;
  final VoidCallback onEditingComplete;

  const TransactionCategoryField({
    super.key,
    required this.transaction,
    required this.categories,
    required this.isEditing,
    required this.onTap,
    required this.onCategorySelected,
    required this.onEditingComplete,
  });

  String? _getSubcategoryName(int? subcategoryId) {
    if (subcategoryId == null) return null;

    for (final category in categories) {
      if (category.subcategories != null) {
        for (final subcategory in category.subcategories!) {
          if (subcategory.id == subcategoryId) {
            return subcategory.name;
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return _buildCategoryDropdown(context);
    }

    // 1. Show actual category if assigned
    if (transaction.subcategoryId != null) {
      return _buildCategorizedDisplay(context);
    }

    // 2. Show prediction if needs review (confidence 50-79%)
    if (transaction.needsReview && transaction.predictedSubcategoryId != null) {
      return _buildSuggestedDisplay(context);
    }

    // 3. No category assigned
    return _buildUncategorizedDisplay(context);
  }

  Widget _buildCategorizedDisplay(BuildContext context) {
    final subcategoryName = _getSubcategoryName(transaction.subcategoryId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              Icons.label,
              size: 16,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                subcategoryName ?? 'Unknown',
                style: const TextStyle(fontSize: 14, color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Show ML badge if auto-assigned
            if (transaction.wasAutoAssigned)
              Tooltip(
                message:
                    'Auto-categorized by ML (${(transaction.predictedConfidence! * 100).toStringAsFixed(0)}%)',
                child: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Colors.blue.shade400,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedDisplay(BuildContext context) {
    final predictedName =
        _getSubcategoryName(transaction.predictedSubcategoryId);
    final confidence =
        ((transaction.predictedConfidence ?? 0) * 100).toStringAsFixed(0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline,
              size: 14,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '$predictedName ($confidence%)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () =>
                  onCategorySelected(transaction.predictedSubcategoryId!),
              child: Icon(
                Icons.check_circle_outline,
                size: 16,
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUncategorizedDisplay(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Ready to Assign',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    int? currentValue = transaction.subcategoryId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: currentValue,
          isExpanded: true,
          hint: const Text('Select Category'),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Ready to Assign'),
            ),
            ..._buildCategoryMenuItems(),
          ],
          onChanged: (subcategoryId) {
            if (subcategoryId != null) {
              onCategorySelected(subcategoryId);
            }
            onEditingComplete();
          },
        ),
      ),
    );
  }

  List<DropdownMenuItem<int?>> _buildCategoryMenuItems() {
    final items = <DropdownMenuItem<int?>>[];
    int headerIndex = 0;

    for (final category in categories) {
      // Add category group header (disabled) with unique negative value
      items.add(
        DropdownMenuItem<int?>(
          value: -(headerIndex++ + 1000),
          enabled: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              category.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      );

      // Add subcategory items
      if (category.subcategories != null) {
        for (final subcategory in category.subcategories!) {
          items.add(
            DropdownMenuItem<int?>(
              value: subcategory.id,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  subcategory.name,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          );
        }
      }
    }

    return items;
  }
}
