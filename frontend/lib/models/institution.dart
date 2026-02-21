class Institution {
  final String domain;
  final String name;
  final List<String> accounts;

  Institution({
    required this.domain,
    required this.name,
    required this.accounts,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      domain: json['domain'],
      name: json['name'],
      accounts: List<String>.from(json['accounts'] ?? []),
    );
  }
}
