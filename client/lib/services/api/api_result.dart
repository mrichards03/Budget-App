class ApiResult<T> {
  final T? data;
  final String? error;
  ApiResult.success(this.data) : error = null;
  ApiResult.error(this.error) : data = null;
  bool get isSuccess => error == null;

  factory ApiResult.fromJson(Map<String, dynamic> json) {
    if (json['error'] != null) {
      return ApiResult.error(json['error'] as String);
    } else {
      return ApiResult.success(json['data'] as T?);
    }
  }
}
