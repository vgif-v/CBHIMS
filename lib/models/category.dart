class Category {
  final int? id;
  final String name;
  final String? description;
  final DateTime? createdAt;

  const Category({
    this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
    };
  }
}
