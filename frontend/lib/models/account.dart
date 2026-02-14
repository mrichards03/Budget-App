class Account {
  final int id;
  final String plaidAccountId;
  final String plaidItemId;
  final String name;
  final String? officialName;
  final String accountType;
  final String accountSubtype;
  final double currentBalance;
  final double? availableBalance;
  final DateTime createdAt;
  
  Account({
    required this.id,
    required this.plaidAccountId,
    required this.plaidItemId,
    required this.name,
    this.officialName,
    required this.accountType,
    required this.accountSubtype,
    required this.currentBalance,
    this.availableBalance,
    required this.createdAt,
  });
  
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      plaidAccountId: json['plaid_account_id'],
      plaidItemId: json['plaid_item_id'],
      name: json['name'],
      officialName: json['official_name'],
      accountType: json['account_type'],
      accountSubtype: json['account_subtype'],
      currentBalance: json['current_balance'].toDouble(),
      availableBalance: json['available_balance']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
