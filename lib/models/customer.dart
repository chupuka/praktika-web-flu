class Customer {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final CustomerCard? card;
  final DateTime? deletedAt;

  const Customer({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.address = '',
    this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        'card': card?.toJson(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: (json['id'] as num?)?.toInt() ?? 0,
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        card: json['card'] == null
            ? null
            : CustomerCard.fromJson(
                Map<String, dynamic>.from(json['card'] as Map),
              ),
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );

  Customer copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? address,
    CustomerCard? card,
    bool clearCard = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Customer(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      card: clearCard ? null : (card ?? this.card),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}

class CustomerCard {
  final String number;
  final String issuedAt;
  final String tier;
  final int points;

  const CustomerCard({
    required this.number,
    required this.issuedAt,
    this.tier = 'basic',
    this.points = 0,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        'issuedAt': issuedAt,
        'tier': tier,
        'points': points,
      };

  factory CustomerCard.fromJson(Map<String, dynamic> json) => CustomerCard(
        number: json['number'] as String? ?? '',
        issuedAt: json['issuedAt'] as String? ?? '',
        tier: json['tier'] as String? ?? 'basic',
        points: (json['points'] as num?)?.toInt() ?? 0,
      );

  CustomerCard copyWith({
    String? number,
    String? issuedAt,
    String? tier,
    int? points,
  }) {
    return CustomerCard(
      number: number ?? this.number,
      issuedAt: issuedAt ?? this.issuedAt,
      tier: tier ?? this.tier,
      points: points ?? this.points,
    );
  }
}
