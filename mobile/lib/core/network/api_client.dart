import 'package:dio/dio.dart';

import '../../config/api_config.dart';
import '../errors/api_exception.dart';
import '../storage/auth_storage.dart';

/// Thin Dio wrapper that speaks the backend's response contract.
///
/// Every non-payment endpoint answers
/// `{ status, message, data }` (`backend/src/utils/responseWrapper.js`), so
/// [getData]/[postData]/… unwrap `data` for you. Use [raw*] when an endpoint
/// deviates — `POST /payments` returns `{ success, data, message }` and
/// `GET /payments` returns `{ data }` with no envelope.
class ApiClient {
  ApiClient({required AuthStorage storage, Dio? dio, this.onSessionExpired})
    : _storage = storage,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              contentType: Headers.jsonContentType,
              // Let non-2xx flow through the error interceptor untouched.
              validateStatus: (int? status) => status != null && status < 400,
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final Dio _dio;
  final AuthStorage _storage;

  /// Invoked when the access token is rejected and cannot be refreshed.
  final Future<void> Function()? onSessionExpired;

  Dio get dio => _dio;

  bool _isPublic(String path) =>
      ApiConfig.publicPaths.any((String p) => path.contains(p));

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path)) {
      final String? token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions request = error.requestOptions;
    final bool isAuthFailure = error.response?.statusCode == 401;
    final bool alreadyRetried = request.extra['phh_retried'] == true;

    if (!isAuthFailure || alreadyRetried || _isPublic(request.path)) {
      return handler.next(error);
    }

    // `POST /auth/refresh-token` (backend/src/controllers/auth.controller.js)
    // swaps a stored refresh token for a fresh 1-day access token.
    final String? refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await onSessionExpired?.call();
      return handler.next(error);
    }

    try {
      final Response<dynamic> refreshed =
          await Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              contentType: Headers.jsonContentType,
            ),
          ).post<dynamic>(
            '/auth/refresh-token',
            data: <String, dynamic>{'refreshToken': refreshToken},
          );

      final dynamic payload = refreshed.data;
      final String? newToken = payload is Map && payload['data'] is Map
          ? (payload['data'] as Map)['token']?.toString()
          : null;

      if (newToken == null || newToken.isEmpty) {
        await onSessionExpired?.call();
        return handler.next(error);
      }

      await _storage.writeAccessToken(newToken);

      request.extra['phh_retried'] = true;
      request.headers['Authorization'] = 'Bearer $newToken';
      final Response<dynamic> retried = await _dio.fetch<dynamic>(request);
      return handler.resolve(retried);
    } on DioException {
      await onSessionExpired?.call();
      return handler.next(error);
    }
  }

  // ── Envelope-aware helpers ────────────────────────────────────────────────

  Future<dynamic> getData(String path, {Map<String, dynamic>? query}) async {
    final Response<dynamic> res = await _guard(
      () => _dio.get<dynamic>(path, queryParameters: query),
    );
    return _unwrap(res);
  }

  Future<dynamic> postData(String path, {Object? body}) async {
    final Response<dynamic> res = await _guard(
      () => _dio.post<dynamic>(path, data: body),
    );
    return _unwrap(res);
  }

  Future<dynamic> putData(String path, {Object? body}) async {
    final Response<dynamic> res = await _guard(
      () => _dio.put<dynamic>(path, data: body),
    );
    return _unwrap(res);
  }

  Future<dynamic> patchData(String path, {Object? body}) async {
    final Response<dynamic> res = await _guard(
      () => _dio.patch<dynamic>(path, data: body),
    );
    return _unwrap(res);
  }

  Future<dynamic> deleteData(String path) async {
    final Response<dynamic> res = await _guard(
      () => _dio.delete<dynamic>(path),
    );
    return _unwrap(res);
  }

  // ── Raw helpers for endpoints that skip the response wrapper ──────────────

  Future<Response<dynamic>> rawPost(String path, {Object? body}) {
    return _guard(() => _dio.post<dynamic>(path, data: body));
  }

  Future<Response<dynamic>> rawGet(String path, {Map<String, dynamic>? query}) {
    return _guard(() => _dio.get<dynamic>(path, queryParameters: query));
  }

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() send,
  ) async {
    try {
      return await send();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  dynamic _unwrap(Response<dynamic> response) {
    final dynamic body = response.data;
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }
}

/// `data` as a map, or an empty map when the endpoint returned null.
Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

/// `data` as a list of maps, tolerating null and non-list payloads.
List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value
      .whereType<Map<dynamic, dynamic>>()
      .map((Map<dynamic, dynamic> e) => Map<String, dynamic>.from(e))
      .toList();
}
