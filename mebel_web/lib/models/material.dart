class FurnitureMaterial {
  final int id;
  final String name;
  final String description;
  final DateTime? deletedAt;

  const FurnitureMaterial({
    required this.id,
    required this.name,
    this.description = '',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory FurnitureMaterial.fromJson(Map<String, dynamic> json) =>
      FurnitureMaterial(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );

  FurnitureMaterial copyWith({
    String? name,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return FurnitureMaterial(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
