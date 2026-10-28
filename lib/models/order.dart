enum OrderStatus {
  newOrder('new', 'Новый'),
  processing('processing', 'В обработке'),
  shipped('shipped', 'Отправлен'),
  delivered('delivered', 'Доставлен'),
  cancelled('cancelled', 'Отменён');

  const OrderStatus(this.apiName, this.label);

  final String apiName;
  final String label;

  static OrderStatus fromApi(String? value) {
    return OrderStatus.values.firstWhere(
      (status) => status.apiName == value,
      orElse: () => OrderStatus.newOrder,
    );
  }
}

enum DeliveryMethod {
  pickup('pickup', 'Самовывоз'),
  delivery('delivery', 'Доставка курьером'),
  mail('mail', 'Почта');

  const DeliveryMethod(this.apiName, this.label);

  final String apiName;
  final String label;

  static DeliveryMethod fromApi(String? value) {
    return DeliveryMethod.values.firstWhere(
      (method) => method.apiName == value,
      orElse: () => DeliveryMethod.pickup,
    );
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final String productName;
  final int quantity;
  final double price;

  const OrderItem({
    this.id = 0,
    this.orderId = 0,
    required this.productId,
    this.productName = '',
    this.quantity = 1,
    required this.price,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'price': price,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        orderId: (json['orderId'] as num?)?.toInt() ?? 0,
        productId: (json['productId'] as num?)?.toInt() ?? 0,
        productName: json['productName'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0,
      );
}

class Order {
  final int id;
  final int customerId;
  final String customerName;
  final OrderStatus status;
  final DeliveryMethod deliveryMethod;
  final double subtotal;
  final double discountPercent;
  final double deliveryCost;
  final double totalPrice;
  final String comment;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final List<OrderItem> items;

  const Order({
    this.id = 0,
    required this.customerId,
    this.customerName = '',
    this.status = OrderStatus.newOrder,
    this.deliveryMethod = DeliveryMethod.pickup,
    this.subtotal = 0,
    this.discountPercent = 0,
    this.deliveryCost = 0,
    this.totalPrice = 0,
    this.comment = '',
    this.createdAt,
    this.deletedAt,
    this.items = const [],
  });

  bool get isDeleted => deletedAt != null;

  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'status': status.apiName,
        'deliveryMethod': deliveryMethod.apiName,
        'subtotal': subtotal,
        'discountPercent': discountPercent,
        'deliveryCost': deliveryCost,
        'totalPrice': totalPrice,
        'comment': comment,
        'createdAt': createdAt?.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'items': [for (final item in items) item.toJson()],
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: (json['id'] as num?)?.toInt() ?? 0,
        customerId: (json['customerId'] as num?)?.toInt() ?? 0,
        customerName: json['customerName'] as String? ?? '',
        status: OrderStatus.fromApi(json['status'] as String?),
        deliveryMethod:
            DeliveryMethod.fromApi(json['deliveryMethod'] as String?),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
        deliveryCost: (json['deliveryCost'] as num?)?.toDouble() ?? 0,
        totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
        comment: json['comment'] as String? ?? '',
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.tryParse(json['createdAt'] as String),
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
        items: [
          for (final item in (json['items'] as List?) ?? const [])
            OrderItem.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
      );
}
