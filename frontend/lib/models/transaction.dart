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
  final bool isTransfer;
  final int? transferAccountId;

  // ML prediction fields
  final int? predictedSubcategoryId;
  final double? predictedConfidence;

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
    this.isTransfer = false,
    this.transferAccountId,
    this.predictedSubcategoryId,
    this.predictedConfidence,
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
      isTransfer: json['is_transfer'] ?? false,
      transferAccountId: json['transfer_account_id'],
      predictedSubcategoryId: json['predicted_subcategory_id'],
      predictedConfidence: json['predicted_confidence']?.toDouble(),
    );
  }

  /// Returns true if transaction has ML prediction but needs manual review
  /// (confidence < 80%)
  bool get needsReview {
    return subcategoryId == null &&
        predictedSubcategoryId != null &&
        predictedConfidence != null &&
        predictedConfidence! < 0.8;
  }

  /// Returns true if transaction was auto-assigned by ML (confidence >= 80%)
  bool get wasAutoAssigned {
    return subcategoryId != null &&
        predictedSubcategoryId == subcategoryId &&
        predictedConfidence != null &&
        predictedConfidence! >= 0.8;
  }
}
