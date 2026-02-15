class Category {
  final int id;
  final String name;
  final String? description;
  final String? color;
  final String? icon;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Subcategory>? subcategories;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.icon,
    required this.isSystem,
    required this.createdAt,
    required this.updatedAt,
    this.subcategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      color: json['color'],
      icon: json['icon'],
      isSystem: json['is_system'],
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
  final String? description;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.isSystem,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      isSystem: json['is_system'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
