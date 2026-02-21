class Category {
  final int id;
  final String name;
  final String? color;
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Subcategory>? subcategories;

  Category({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
    this.subcategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      icon: json['icon'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List)
              .map((s) => Subcategory.fromJson(s))
              .toList()
          : null,
    );
  }
}

class Subcategory {
  final int id;
  final int categoryId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
