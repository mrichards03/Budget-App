import 'transaction.dart';

class CategoryInfo {
  final int id;
  final String name;
  final String? color;
  final String? icon;

  CategoryInfo({
    required this.id,
    required this.name,
    this.color,
    this.icon,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      icon: json['icon'],
    );
  }
}

class SubcategoryInfo {
  final int id;
  final String name;
  final int categoryId;

  SubcategoryInfo({
    required this.id,
    required this.name,
    required this.categoryId
  });

  factory SubcategoryInfo.fromJson(Map<String, dynamic> json) {
    return SubcategoryInfo(
      id: json['id'],
      name: json['name'],
      categoryId: json['category_id']
    );
  }
}

class AccountInfo {
  final String id;
  final String name;
  final String? accountType;
  final double currentBalance;

  AccountInfo({
    required this.id,
    required this.name,
    this.accountType,
    required this.currentBalance,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      id: json['id'],
      name: json['name'],
      accountType: json['type'],
      currentBalance: json['current_balance'].toDouble(),
    );
  }
}

class AnalyticsSummary {
  final double totalSpending;
  final double totalIncome;
  final double net;
  final int transactionCount;
  final int dateRangeDays;
  final double monthlyAverageSpending;
  final double monthlyAverageIncome;
  final double dailyAverageSpending;
  final double dailyAverageIncome;
  final Map<int, double> categoryBreakdown;
  final Map<int, double> subcategoryBreakdown;

  AnalyticsSummary({
    required this.totalSpending,
    required this.totalIncome,
    required this.net,
    required this.transactionCount,
    required this.dateRangeDays,
    required this.monthlyAverageSpending,
    required this.monthlyAverageIncome,
    required this.dailyAverageSpending,
    required this.dailyAverageIncome,
    required this.categoryBreakdown,
    required this.subcategoryBreakdown,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalSpending: json['total_spending'].toDouble(),
      totalIncome: json['total_income'].toDouble(),
      net: json['net'].toDouble(),
      transactionCount: json['transaction_count'],
      dateRangeDays: json['date_range_days'],
      monthlyAverageSpending: json['monthly_average_spending'].toDouble(),
      monthlyAverageIncome: json['monthly_average_income'].toDouble(),
      dailyAverageSpending: json['daily_average_spending'].toDouble(),
      dailyAverageIncome: json['daily_average_income'].toDouble(),
      categoryBreakdown: Map<int, double>.from(
        (json['category_breakdown'] as Map).map(
          (k, v) => MapEntry(int.parse(k.toString()), v.toDouble()),
        ),
      ),
      subcategoryBreakdown: Map<int, double>.from(
        (json['subcategory_breakdown'] as Map).map(
          (k, v) => MapEntry(int.parse(k.toString()), v.toDouble()),
        ),
      ),
    );
  }
}

class AnalyticsResponse {
  final List<Transaction> transactions;
  final Map<int, CategoryInfo> categories;
  final Map<int, SubcategoryInfo> subcategories;
  final Map<String, AccountInfo> accounts;
  final AnalyticsSummary summary;

  AnalyticsResponse({
    required this.transactions,
    required this.categories,
    required this.subcategories,
    required this.accounts,
    required this.summary,
  });

  factory AnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return AnalyticsResponse(
      transactions: (json['transactions'] as List)
          .map((t) => Transaction.fromJson(t))
          .toList(),
      categories: Map<int, CategoryInfo>.from(
        (json['categories'] as Map).map(
          (k, v) => MapEntry(int.parse(k.toString()), CategoryInfo.fromJson(v)),
        ),
      ),
      subcategories: Map<int, SubcategoryInfo>.from(
        (json['subcategories'] as Map).map(
          (k, v) =>
              MapEntry(int.parse(k.toString()), SubcategoryInfo.fromJson(v)),
        ),
      ),
      accounts: Map<String, AccountInfo>.from(
        (json['accounts'] as Map).map(
          (k, v) => MapEntry(k.toString(), AccountInfo.fromJson(v)),
        ),
      ),
      summary: AnalyticsSummary.fromJson(json['summary']),
    );
  }

  // Helper methods for easy lookups
  String? getCategoryName(int? subcategoryId) {
    if (subcategoryId == null) return null;
    final subcategory = subcategories[subcategoryId];
    if (subcategory == null) return null;
    return categories[subcategory.categoryId]?.name;
  }

  String? getSubcategoryName(int? subcategoryId) {
    if (subcategoryId == null) return null;
    return subcategories[subcategoryId]?.name;
  }

  String? getAccountName(String accountId) {
    return accounts[accountId]?.name;
  }

  List<Transaction> getTransactionsForCategory(int categoryId) {
    return transactions.where((t) {
      if (t.subcategoryId == null) return false;
      final subcategory = subcategories[t.subcategoryId];
      return subcategory?.categoryId == categoryId;
    }).toList();
  }

  List<Transaction> getTransactionsForSubcategory(int subcategoryId) {
    return transactions.where((t) => t.subcategoryId == subcategoryId).toList();
  }
}
