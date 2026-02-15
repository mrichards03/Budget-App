class Transaction {
  final int id;
  final String plaidTransactionId;
  final int accountId;
  final double amount;
  final DateTime date;
  final String name;
  final String? merchantName;
  final String? category;
  final String? categoryDetailed;
  final String? predictedCategory;
  final double? predictedConfidence;
  final bool pending;
  final DateTime createdAt;
  final int? subcategoryId;

  Transaction({
    required this.id,
    required this.plaidTransactionId,
    required this.accountId,
    required this.amount,
    required this.date,
    required this.name,
    this.merchantName,
    this.category,
    this.categoryDetailed,
    this.predictedCategory,
    this.predictedConfidence,
    required this.pending,
    required this.createdAt,
    this.subcategoryId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      plaidTransactionId: json['plaid_transaction_id'],
      accountId: json['account_id'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      name: json['name'],
      merchantName: json['merchant_name'],
      category: json['category'],
      categoryDetailed: json['category_detailed'],
      predictedCategory: json['predicted_category'],
      predictedConfidence: json['predicted_confidence']?.toDouble(),
      pending: json['pending'],
      createdAt: DateTime.parse(json['created_at']),
      subcategoryId: json['subcategory_id'],
    );
  }
}
