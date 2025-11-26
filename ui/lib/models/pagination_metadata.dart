class PaginationMetadata {
  final int currentPage;
  final int pageSize;
  final int firstPage;
  final int lastPage;
  final int totalRecords;

  PaginationMetadata({
    required this.currentPage,
    required this.pageSize,
    required this.firstPage,
    required this.lastPage,
    required this.totalRecords,
  });

  factory PaginationMetadata.fromJson(Map<String, dynamic> json) {
    return PaginationMetadata(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 10,
      firstPage: (json['first_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      totalRecords: (json['total_records'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'page_size': pageSize,
      'first_page': firstPage,
      'last_page': lastPage,
      'total_records': totalRecords,
    };
  }

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > firstPage;
}
