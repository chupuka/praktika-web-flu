class ShopStats {
  final int products;
  final int categories;
  final int manufacturers;
  final int materials;
  final int customers;
  final int users;
  final double stockValue;
  final double avgPrice;
  final int outOfStock;
  final int lowStock;
  final int orders;
  final double revenue;
  final double avgRating;

  const ShopStats({
    this.products = 0,
    this.categories = 0,
    this.manufacturers = 0,
    this.materials = 0,
    this.customers = 0,
    this.users = 0,
    this.stockValue = 0,
    this.avgPrice = 0,
    this.outOfStock = 0,
    this.lowStock = 0,
    this.orders = 0,
    this.revenue = 0,
    this.avgRating = 0,
  });

  factory ShopStats.fromJson(Map<String, dynamic> json) => ShopStats(
        products: (json['products'] as num?)?.toInt() ?? 0,
        categories: (json['categories'] as num?)?.toInt() ?? 0,
        manufacturers: (json['manufacturers'] as num?)?.toInt() ?? 0,
        materials: (json['materials'] as num?)?.toInt() ?? 0,
        customers: (json['customers'] as num?)?.toInt() ?? 0,
        users: (json['users'] as num?)?.toInt() ?? 0,
        stockValue: (json['stock_value'] as num?)?.toDouble() ?? 0,
        avgPrice: (json['avg_price'] as num?)?.toDouble() ?? 0,
        outOfStock: (json['out_of_stock'] as num?)?.toInt() ?? 0,
        lowStock: (json['low_stock'] as num?)?.toInt() ?? 0,
        orders: (json['orders'] as num?)?.toInt() ?? 0,
        revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
        avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      );
}

class CategoryStat {
  final int id;
  final String name;
  final int productCount;
  final double stockValue;

  const CategoryStat({
    required this.id,
    required this.name,
    required this.productCount,
    required this.stockValue,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) => CategoryStat(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        productCount: (json['product_count'] as num?)?.toInt() ?? 0,
        stockValue: (json['stock_value'] as num?)?.toDouble() ?? 0,
      );
}
