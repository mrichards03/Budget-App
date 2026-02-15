class Budget {
  final int? id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<SubcategoryBudget>? subcategoryBudgets;
  final double? totalAllocated;

  Budget({
    this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.subcategoryBudgets,
    this.totalAllocated,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      name: json['name'],
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      subcategoryBudgets: json['subcategory_budgets'] != null
          ? (json['subcategory_budgets'] as List)
              .map((c) => SubcategoryBudget.fromJson(c))
              .toList()
          : null,
      totalAllocated: json['total_allocated']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      if (subcategoryBudgets != null)
        'subcategory_budgets':
            subcategoryBudgets!.map((c) => c.toJson()).toList(),
    };
  }

  Budget copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SubcategoryBudget>? subcategoryBudgets,
    double? totalAllocated,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subcategoryBudgets: subcategoryBudgets ?? this.subcategoryBudgets,
      totalAllocated: totalAllocated ?? this.totalAllocated,
    );
  }
}

class SubcategoryBudget {
  final int? id;
  final int? budgetId;
  final int subcategoryId;
  final String categoryName;
  final String subcategoryName;
  final double allocatedAmount;
  final double? currentSpending;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubcategoryBudget({
    this.id,
    this.budgetId,
    required this.subcategoryId,
    required this.categoryName,
    required this.subcategoryName,
    required this.allocatedAmount,
    this.currentSpending,
    this.createdAt,
    this.updatedAt,
  });

  factory SubcategoryBudget.fromJson(Map<String, dynamic> json) {
    return SubcategoryBudget(
      id: json['id'],
      budgetId: json['budget_id'],
      subcategoryId: json['subcategory_id'],
      categoryName: json['category_name'],
      subcategoryName: json['subcategory_name'],
      allocatedAmount: json['allocated_amount'].toDouble(),
      currentSpending: json['current_spending']?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subcategory_id': subcategoryId,
      'allocated_amount': allocatedAmount,
    };
  }

  SubcategoryBudget copyWith({
    int? id,
    int? budgetId,
    int? subcategoryId,
    String? categoryName,
    String? subcategoryName,
    double? allocatedAmount,
    double? currentSpending,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubcategoryBudget(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      currentSpending: currentSpending ?? this.currentSpending,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
