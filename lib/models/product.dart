class Product {
  final int? id;
  final String productName;
  final int? categoryId;
  final String? categoryName; // joined from categories table
  final int quantity;
  final String unit;
  final bool isActive;
  final String? remarks;
  final DateTime? createdAt;

  const Product({
    this.id,
    required this.productName,
    this.categoryId,
    this.categoryName,
    this.quantity = 0,
    this.unit = 'pcs',
    this.isActive = true,
    this.remarks,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String? catName;
    if (json['categories'] != null && json['categories'] is Map) {
      catName = json['categories']['name'] as String?;
    }

    return Product(
      id: json['id'] as int?,
      productName: json['product_name'] as String? ?? '',
      categoryId: json['category_id'] as int?,
      categoryName: catName,
      quantity: json['quantity'] as int? ?? 0,
      unit: json['unit'] as String? ?? 'pcs',
      isActive: json['is_active'] as bool? ?? true,
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// Serializes fields for INSERT / UPDATE.
  Map<String, dynamic> toInsertJson() {
    return {
      'product_name': productName,
      if (categoryId != null) 'category_id': categoryId,
      'quantity': quantity,
      'unit': unit,
      'is_active': isActive,
      if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
    };
  }

  Product copyWith({
    int? id,
    String? productName,
    int? categoryId,
    String? categoryName,
    int? quantity,
    String? unit,
    bool? isActive,
    String? remarks,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          productName == other.productName;

  @override
  int get hashCode => id.hashCode ^ productName.hashCode;
}
