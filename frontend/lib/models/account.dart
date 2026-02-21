class Account {
  final String id;
  final String name;
  final String currencyCode;
  final double currentBalance;
  final double? availableBalance;
  final DateTime balanceDate;
  final String organizationDomain;
  final String? accountType;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.currentBalance,
    this.availableBalance,
    required this.balanceDate,
    required this.organizationDomain,
    this.accountType,
    required this.createdAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      currencyCode: json['currency_code'],
      currentBalance: json['current_balance'].toDouble(),
      availableBalance: json['available_balance']?.toDouble(),
      balanceDate: DateTime.parse(json['balance_date']),
      organizationDomain: json['organization_domain'],
      accountType: json['account_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
