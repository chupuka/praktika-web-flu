import 'order.dart';

class OrderQuery {
  final String search;
  final OrderStatus? status;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const OrderQuery({
    this.search = '',
    this.status,
    this.sortField = 'createdAt',
    this.sortAscending = false,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  static const _unset = Object();

  OrderQuery copyWith({
    String? search,
    Object? status = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return OrderQuery(
      search: search ?? this.search,
      status: status == _unset ? this.status : status as OrderStatus?,
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
    if (status != null) params['status'] = status!.apiName;
    params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    if (page != 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['deleted'] = '1';
    return params;
  }

  static OrderQuery fromParameters(Map<String, String> params) {
    int? tryInt(String? raw) =>
        raw == null || raw.isEmpty ? null : int.tryParse(raw);
    final sortParts = (params['sort'] ?? 'createdAt,desc').split(',');
    final rawStatus = params['status'];
    OrderStatus? status;
    for (final item in OrderStatus.values) {
      if (item.apiName == rawStatus) status = item;
    }
    return OrderQuery(
      search: params['search'] ?? '',
      status: status,
      sortField: sortParts.first,
      sortAscending: sortParts.length < 2 || sortParts[1] != 'desc',
      page: tryInt(params['page']) ?? 1,
      size: tryInt(params['size']) ?? 10,
      includeDeleted: params['deleted'] == '1',
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OrderQuery &&
        search == other.search &&
        status == other.status &&
        sortField == other.sortField &&
        sortAscending == other.sortAscending &&
        page == other.page &&
        size == other.size &&
        includeDeleted == other.includeDeleted;
  }

  @override
  int get hashCode => Object.hash(
        search,
        status,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );
}
