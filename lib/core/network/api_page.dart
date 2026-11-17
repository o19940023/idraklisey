class ApiPage<T> {
  const ApiPage({
    required this.items,
    this.page = 1,
    this.perPage = 20,
    this.total = 0,
    this.lastPage = 1,
  });

  final List<T> items;
  final int page;
  final int perPage;
  final int total;
  final int lastPage;

  bool get hasMore => page < lastPage;
}

/// Parses the standard mobile envelope into a typed page of JSON maps.
ApiPage<Map<String, dynamic>> parsePage(dynamic response) {
  final data = response is Map ? response['data'] : null;
  final meta = response is Map ? response['meta'] : null;

  final rawItems = data is List ? data : const [];
  final items = rawItems
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  return ApiPage<Map<String, dynamic>>(
    items: items,
    page: (meta is Map ? (meta['page'] as num?)?.toInt() : null) ?? 1,
    perPage: (meta is Map ? (meta['per_page'] as num?)?.toInt() : null) ?? 20,
    total: (meta is Map ? (meta['total'] as num?)?.toInt() : null) ?? items.length,
    lastPage: (meta is Map ? (meta['last_page'] as num?)?.toInt() : null) ?? 1,
  );
}

Map<String, dynamic> parseData(dynamic response) {
  final data = response is Map ? response['data'] : null;
  if (data is Map) return Map<String, dynamic>.from(data);
  return {};
}
