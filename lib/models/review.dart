class Review {
  final int id;
  final int productId;
  final int customerId;
  final String customerName;
  final int rating;
  final String text;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  const Review({
    this.id = 0,
    required this.productId,
    required this.customerId,
    this.customerName = '',
    required this.rating,
    required this.text,
    this.createdAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'text': text,
        'createdAt': createdAt?.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: (json['id'] as num?)?.toInt() ?? 0,
        productId: (json['productId'] as num?)?.toInt() ?? 0,
        customerId: (json['customerId'] as num?)?.toInt() ?? 0,
        customerName: json['customerName'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        text: json['text'] as String? ?? '',
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.tryParse(json['createdAt'] as String),
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );
}
