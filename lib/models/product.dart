class Product {
  final int id;
  final String name;
  final String sku;
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
    this.sku = '',
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'description': description,
        'style': style,
        'price': price,
        'stock': stock,
        'width': width,
        'depth': depth,
        'height': height,
        'weight': weight,
        'color': color,
        'categoryId': categoryId,
        'manufacturerId': manufacturerId,
        'materialIds': materialIds,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        description: json['description'] as String? ?? '',
        style: json['style'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        width: (json['width'] as num?)?.toDouble(),
        depth: (json['depth'] as num?)?.toDouble(),
        height: (json['height'] as num?)?.toDouble(),
        weight: (json['weight'] as num?)?.toDouble(),
        color: json['color'] as String? ?? '',
        categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
        manufacturerId: (json['manufacturerId'] as num?)?.toInt() ?? 0,
        materialIds: (json['materialIds'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const <int>[],
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );

  Product copyWith({
    String? name,
    String? sku,
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
      sku: sku ?? this.sku,
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
