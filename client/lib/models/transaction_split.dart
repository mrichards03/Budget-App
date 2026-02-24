class TransactionSplit {
  final int id;
  final int subcategoryId;
  final double amount;
  final String? memo;
  final DateTime createdAt;

  TransactionSplit({
    required this.id,
    required this.subcategoryId,
    required this.amount,
    this.memo,
    required this.createdAt,
  });

  factory TransactionSplit.fromJson(Map<String, dynamic> json) {
    return TransactionSplit(
      id: json['id'],
      subcategoryId: json['subcategory_id'],
      amount: json['amount'].toDouble(),
      memo: json['memo'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
