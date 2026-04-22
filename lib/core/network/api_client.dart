import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/app_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.code});

  final String message;
  final int? code;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            responseType: ResponseType.json,
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final skipAuth = options.extra['skipAuth'] == true;
          final token = AppStorage.instance.accessToken;
          final tenantId = AppStorage.instance.tenantId;
          if (!skipAuth && token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (tenantId != null) {
            options.headers['tenant-id'] = tenantId.toString();
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (_shouldRefresh(error)) {
            try {
              final token = await _refreshAccessToken();
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch<dynamic>(options);
              handler.resolve(response);
              return;
            } catch (_) {
              await AppStorage.instance.clearTokens();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  Completer<String>? _refreshCompleter;

  bool _shouldRefresh(DioException error) {
    final statusCode = error.response?.statusCode;
    final isRefreshRequest =
        error.requestOptions.path.contains('/system/auth/refresh-token');
    final refreshToken = AppStorage.instance.refreshToken;
    return statusCode == 401 &&
        !isRefreshRequest &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }

  Future<String> _refreshAccessToken() async {
    final existing = _refreshCompleter;
    if (existing != null) {
      return existing.future;
    }

    final completer = Completer<String>();
    _refreshCompleter = completer;
    try {
      final refreshToken = AppStorage.instance.refreshToken!;
      final response = await _dio.post<dynamic>(
        '/system/auth/refresh-token',
        queryParameters: {'refreshToken': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
      final body = _readJsonMap(response.data);
      final code = _extractCode(body);
      if (!_isSuccessCode(code)) {
        throw ApiException(_extractMessage(body), code: code);
      }
      final data = _extractData(body);
      final dataMap =
          data is Map<String, dynamic> ? data : <String, dynamic>{};
      final accessToken = (dataMap['accessToken'] ?? '') as String;
      await AppStorage.instance.saveTokens(
        accessToken: accessToken,
        refreshToken: dataMap['refreshToken'] as String?,
        expiresTime: (dataMap['expiresTime'] as num?)?.toInt(),
      );
      completer.complete(accessToken);
      return accessToken;
    } catch (error) {
      completer.completeError(error);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic raw) parser,
    bool skipAuth = false,
  }) {
    return _request<T>(
      path,
      method: 'GET',
      queryParameters: queryParameters,
      parser: parser,
      skipAuth: skipAuth,
    );
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic raw) parser,
    bool skipAuth = false,
  }) {
    return _request<T>(
      path,
      method: 'POST',
      data: data,
      queryParameters: queryParameters,
      parser: parser,
      skipAuth: skipAuth,
    );
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic raw) parser,
    bool skipAuth = false,
  }) {
    return _request<T>(
      path,
      method: 'PUT',
      data: data,
      queryParameters: queryParameters,
      parser: parser,
      skipAuth: skipAuth,
    );
  }

  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic raw) parser,
    bool skipAuth = false,
  }) {
    return _request<T>(
      path,
      method: 'DELETE',
      data: data,
      queryParameters: queryParameters,
      parser: parser,
      skipAuth: skipAuth,
    );
  }

  Future<Map<String, dynamic>> postRaw(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool skipAuth = false,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: 'POST', extra: {'skipAuth': skipAuth}),
      );
      return _readJsonMap(response.data);
    } on DioException catch (error) {
      throw ApiException(
        _extractDioMessage(error),
        code: _extractDioCode(error),
      );
    }
  }

  Future<T> _request<T>(
    String path, {
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic raw) parser,
    bool skipAuth = false,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method, extra: {'skipAuth': skipAuth}),
      );
      final rawBody = response.data;
      if (rawBody is Map<String, dynamic>) {
        final code = _extractCode(rawBody);
        if (code != null) {
          if (!_isSuccessCode(code)) {
            throw ApiException(_extractMessage(rawBody), code: code);
          }
          return parser(_extractData(rawBody));
        }
      }
      return parser(rawBody);
    } on DioException catch (error) {
      throw ApiException(
        _extractDioMessage(error),
        code: _extractDioCode(error),
      );
    }
  }

  bool _isSuccessCode(int? code) => code == 0 || code == 200;

  int? _extractCode(Map<String, dynamic> body) {
    return (body['code'] as num?)?.toInt();
  }

  dynamic _extractData(Map<String, dynamic> body) {
    return body.containsKey('data') ? body['data'] : body;
  }

  String _extractMessage(Map<String, dynamic> body) {
    final raw = body['msg'] ?? body['message'] ?? body['error'] ?? body['detail'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return '请求失败，请稍后重试';
  }

  int? _extractDioCode(DioException error) {
    final response = error.response?.data;
    if (response is Map<String, dynamic>) {
      return (response['code'] as num?)?.toInt();
    }
    return error.response?.statusCode;
  }

  String _extractDioMessage(DioException error) {
    final response = error.response?.data;
    if (response is Map<String, dynamic>) {
      return _extractMessage(response);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return '网络连接超时，请检查服务器或网络状态';
    }
    if (error.type == DioExceptionType.connectionError) {
      return '网络连接失败，请检查接口地址或网络状态';
    }
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return '网络请求失败，请稍后重试';
  }

  Map<String, dynamic> _readJsonMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    throw ApiException('服务返回数据格式错误，请联系管理员');
  }
}
