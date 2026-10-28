class ProductQuery {
  final String search;
  final int? categoryId;
  final int? manufacturerId;
  final double? priceFrom;
  final double? priceTo;
  final String? style;
  final bool inStockOnly;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const ProductQuery({
    this.search = '',
    this.categoryId,
    this.manufacturerId,
    this.priceFrom,
    this.priceTo,
    this.style,
    this.inStockOnly = false,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  static const _unset = Object();

  ProductQuery copyWith({
    String? search,
    Object? categoryId = _unset,
    Object? manufacturerId = _unset,
    Object? priceFrom = _unset,
    Object? priceTo = _unset,
    Object? style = _unset,
    bool? inStockOnly,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ProductQuery(
      search: search ?? this.search,
      categoryId: categoryId == _unset ? this.categoryId : categoryId as int?,
      manufacturerId: manufacturerId == _unset
          ? this.manufacturerId
          : manufacturerId as int?,
      priceFrom: priceFrom == _unset ? this.priceFrom : priceFrom as double?,
      priceTo: priceTo == _unset ? this.priceTo : priceTo as double?,
      style: style == _unset ? this.style : style as String?,
      inStockOnly: inStockOnly ?? this.inStockOnly,
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
    if (categoryId != null) params['categoryId'] = '$categoryId';
    if (manufacturerId != null) params['manufacturerId'] = '$manufacturerId';
    if (priceFrom != null) params['priceFrom'] = '${priceFrom!.toInt()}';
    if (priceTo != null) params['priceTo'] = '${priceTo!.toInt()}';
    if (style != null && style!.isNotEmpty) params['style'] = style!;
    if (inStockOnly) params['inStock'] = '1';
    params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    if (page != 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['deleted'] = '1';
    return params;
  }

  static ProductQuery fromParameters(Map<String, String> params) {
    int? tryInt(String? raw) =>
        raw == null || raw.isEmpty ? null : int.tryParse(raw);
    double? tryDouble(String? raw) =>
        raw == null || raw.isEmpty ? null : double.tryParse(raw);
    final sortParts = (params['sort'] ?? 'name,asc').split(',');
    return ProductQuery(
      search: params['search'] ?? '',
      categoryId: tryInt(params['categoryId']),
      manufacturerId: tryInt(params['manufacturerId']),
      priceFrom: tryDouble(params['priceFrom']),
      priceTo: tryDouble(params['priceTo']),
      style: params['style'],
      inStockOnly: params['inStock'] == '1',
      sortField: sortParts.first,
      sortAscending: sortParts.length < 2 || sortParts[1] != 'desc',
      page: tryInt(params['page']) ?? 1,
      size: tryInt(params['size']) ?? 10,
      includeDeleted: params['deleted'] == '1',
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProductQuery &&
        search == other.search &&
        categoryId == other.categoryId &&
        manufacturerId == other.manufacturerId &&
        priceFrom == other.priceFrom &&
        priceTo == other.priceTo &&
        style == other.style &&
        inStockOnly == other.inStockOnly &&
        sortField == other.sortField &&
        sortAscending == other.sortAscending &&
        page == other.page &&
        size == other.size &&
        includeDeleted == other.includeDeleted;
  }

  @override
  int get hashCode => Object.hash(
        search,
        categoryId,
        manufacturerId,
        priceFrom,
        priceTo,
        style,
        inStockOnly,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );
}
