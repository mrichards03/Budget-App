class Transaction {
  final int id;
  final int accountId;
  final double amount;
  final DateTime effectiveDate;
  final String displayName; // Backend's computed display_name
  final String? memo;
  final int? subcategoryId;
  final bool pending;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.effectiveDate,
    required this.displayName,
    this.memo,
    this.subcategoryId,
    required this.pending,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      accountId: json['account_id'],
      amount: json['amount'].toDouble(),
      effectiveDate: DateTime.parse(json['effective_date']),
      displayName: json['display_name'],
      memo: json['memo'],
      subcategoryId: json['subcategory_id'],
      pending: json['pending'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
