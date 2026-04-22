class ApiResponse<T> {
  ApiResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  final int code;
  final String message;
  final T data;

  bool get isSuccess => code == 0 || code == 200;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw) parser,
  ) {
    return ApiResponse<T>(
      code: (json['code'] as num?)?.toInt() ?? -1,
      message: (json['msg'] ?? json['message'] ?? '') as String,
      data: parser(json['data']),
    );
  }
}

class PageResult<T> {
  PageResult({
    required this.total,
    required this.list,
  });

  final int total;
  final List<T> list;

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> raw) parser,
  ) {
    final rawList = (json['list'] as List<dynamic>? ?? const []);
    return PageResult<T>(
      total: (json['total'] as num?)?.toInt() ?? 0,
      list: rawList
          .whereType<Map<String, dynamic>>()
          .map(parser)
          .toList(growable: false),
    );
  }
}
