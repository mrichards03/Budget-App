class Institution {
  final String itemId;
  final String institutionId;
  final String institutionName;
  final List<String> accounts;

  Institution({
    required this.itemId,
    required this.institutionId,
    required this.institutionName,
    required this.accounts,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      itemId: json['item_id'],
      institutionId: json['institution_id'],
      institutionName: json['institution_name'],
      accounts: List<String>.from(json['accounts'] ?? []),
    );
  }
}
