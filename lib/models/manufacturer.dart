class Manufacturer {
  final int id;
  final String name;
  final String country;
  final String contactEmail;
  final DateTime? deletedAt;

  const Manufacturer({
    required this.id,
    required this.name,
    this.country = '',
    this.contactEmail = '',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'contactEmail': contactEmail,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Manufacturer.fromJson(Map<String, dynamic> json) => Manufacturer(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        country: json['country'] as String? ?? '',
        contactEmail: json['contactEmail'] as String? ?? '',
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );

  Manufacturer copyWith({
    String? name,
    String? country,
    String? contactEmail,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Manufacturer(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      contactEmail: contactEmail ?? this.contactEmail,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
