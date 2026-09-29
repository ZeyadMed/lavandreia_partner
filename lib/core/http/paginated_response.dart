/// شكل الريسبونس المتقسم لصفحات اللي السيرفر بيرجعه:
/// { "pageIndex", "pageSize", "count", "totalPages", "data": [..] }
///
/// أسماء [items] و [pagination] هي اللي [GenericPaginationCubit] بيدور عليها
class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMeta pagination;

  const PaginatedResponse({required this.items, required this.pagination});

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PaginatedResponse(
      items: (json['data'] as List? ?? [])
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: PaginationMeta.fromJson(json),
    );
  }
}

class PaginationMeta {
  final int currentPage;
  final int perPage;
  final int total;
  final int pagesCount;

  const PaginationMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.pagesCount,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['pageIndex'] as int? ?? 1,
      perPage: json['pageSize'] as int? ?? 0,
      total: json['count'] as int? ?? 0,
      pagesCount: json['totalPages'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'PaginationMeta(page: $currentPage/$pagesCount, perPage: $perPage, total: $total)';
}
