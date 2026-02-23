class Budget {
  final int? id;
  final String name;
  final int month;
  final int year;
  final DateTime startDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<SubcategoryBudget>? subcategoryBudgets;

  Budget({
    this.id,
    required this.name,
    required this.month,
    required this.year,
    required this.startDate,
    this.createdAt,
    this.updatedAt,
    this.subcategoryBudgets,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      name: json['name'],
      month: json['month'],
      year: json['year'],
      startDate: DateTime.parse(json['start_date']),
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'month': month,
      'year': year,
      if (subcategoryBudgets != null)
        'subcategory_budgets': subcategoryBudgets!
            .map((c) => c.toJson())
            .toList(),
    };
  }

  Budget copyWith({
    int? id,
    String? name,
    int? month,
    int? year,
    DateTime? startDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SubcategoryBudget>? subcategoryBudgets
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      month: month ?? this.month,
      year: year ?? this.year,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subcategoryBudgets: subcategoryBudgets ?? this.subcategoryBudgets
    );
  }
}

class SubcategoryBudget {
  final int? id;
  final int? budgetId;
  final int subcategoryId;
  final String categoryName;
  final String subcategoryName;
  final double monthlyAssigned;
  final double monthlyTarget;
  final double totalBalance;
  final double monthlyActivity;
  final double monthlyAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubcategoryBudget({
    this.id,
    this.budgetId,
    required this.subcategoryId,
    required this.categoryName,
    required this.subcategoryName,
    required this.monthlyAssigned,
    required this.monthlyTarget,
    required this.totalBalance,
    required this.monthlyActivity,
    required this.monthlyAvailable,
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
      monthlyAssigned: json['monthly_assigned'].toDouble(),
      monthlyTarget: json['monthly_target'].toDouble(),
      totalBalance: json['total_balance'].toDouble(),
      monthlyActivity: json['monthly_activity'].toDouble(),
      monthlyAvailable: json['monthly_available'].toDouble(),
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
      'monthly_assigned': monthlyAssigned,
      'monthly_target': monthlyTarget,
    };
  }

  SubcategoryBudget copyWith({
    int? id,
    int? budgetId,
    int? subcategoryId,
    String? categoryName,
    String? subcategoryName,
    double? monthlyAssigned,
    double? monthlyTarget,
    double? totalBalance,
    double? monthlyActivity,
    double? monthlyAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubcategoryBudget(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      monthlyAssigned: monthlyAssigned ?? this.monthlyAssigned,
      monthlyTarget: monthlyTarget ?? this.monthlyTarget,
      totalBalance: totalBalance ?? this.totalBalance,
      monthlyActivity: monthlyActivity ?? this.monthlyActivity,
      monthlyAvailable: monthlyAvailable ?? this.monthlyAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
