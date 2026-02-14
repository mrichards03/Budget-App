class Budget {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final List<BudgetCategory> categories;
  final DateTime createdAt;
  
  Budget({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.categories,
    required this.createdAt,
  });
  
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      name: json['name'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      categories: (json['categories'] as List?)
          ?.map((cat) => BudgetCategory.fromJson(cat))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class BudgetCategory {
  final int id;
  final int budgetId;
  final String category;
  final double goalAmount;
  final double currentSpending;
  
  BudgetCategory({
    required this.id,
    required this.budgetId,
    required this.category,
    required this.goalAmount,
    required this.currentSpending,
  });
  
  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      id: json['id'],
      budgetId: json['budget_id'],
      category: json['category'],
      goalAmount: json['goal_amount'].toDouble(),
      currentSpending: json['current_spending']?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'budget_id': budgetId,
      'category': category,
      'goal_amount': goalAmount,
      'current_spending': currentSpending,
    };
  }
  
  double get percentageUsed {
    if (goalAmount == 0) return 0;
    return (currentSpending / goalAmount) * 100;
  }
  
  double get remainingAmount => goalAmount - currentSpending;
}
