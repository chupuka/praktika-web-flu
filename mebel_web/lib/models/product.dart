class Product {
  final int id;
  final String name;
  final String description;
  final String style;
  final double price;
  final int stock;
  final double? width;
  final double? depth;
  final double? height;
  final double? weight;
  final String color;
  final int categoryId;
  final int manufacturerId;
  final List<int> materialIds;
  final DateTime? deletedAt;

  const Product({
    required this.id,
    required this.name,
    this.description = '',
    this.style = '',
    required this.price,
    this.stock = 0,
    this.width,
    this.depth,
    this.height,
    this.weight,
    this.color = '',
    required this.categoryId,
    required this.manufacturerId,
    this.materialIds = const [],
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get inStock => stock > 0;

  Product copyWith({
    String? name,
    String? description,
    String? style,
    double? price,
    int? stock,
    double? width,
    double? depth,
    double? height,
    double? weight,
    String? color,
    int? categoryId,
    int? manufacturerId,
    List<int>? materialIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      style: style ?? this.style,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      width: width ?? this.width,
      depth: depth ?? this.depth,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      color: color ?? this.color,
      categoryId: categoryId ?? this.categoryId,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      materialIds: materialIds ?? this.materialIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
