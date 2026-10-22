class MaterialQuery {
  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const MaterialQuery({
    this.search = '',
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  MaterialQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return MaterialQuery(
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  Map<String, String> toParameters() {
    final params = <String, String>{};
    if (search.trim().isNotEmpty) params['search'] = search.trim();
    params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    if (page != 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['deleted'] = '1';
    return params;
  }

  static MaterialQuery fromParameters(Map<String, String> params) {
    int? tryInt(String? raw) =>
        raw == null || raw.isEmpty ? null : int.tryParse(raw);
    final sortParts = (params['sort'] ?? 'name,asc').split(',');
    return MaterialQuery(
      search: params['search'] ?? '',
      sortField: sortParts.first,
      sortAscending: sortParts.length < 2 || sortParts[1] != 'desc',
      page: tryInt(params['page']) ?? 1,
      size: tryInt(params['size']) ?? 10,
      includeDeleted: params['deleted'] == '1',
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MaterialQuery &&
        search == other.search &&
        sortField == other.sortField &&
        sortAscending == other.sortAscending &&
        page == other.page &&
        size == other.size &&
        includeDeleted == other.includeDeleted;
  }

  @override
  int get hashCode => Object.hash(
        search,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );
}
