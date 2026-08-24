import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';
import 'token_storage_service.dart';

/// Centralized HTTP API Client with Zero-Caching Policy, Background Token Refresh, and Detailed Debug Logging
class ApiClient {
  ApiClient({
    Dio? dio,
    TokenStorageService? tokenStorage,
  })  : _tokenStorage = tokenStorage ?? TokenStorageService(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                connectTimeout: ApiEndpoints.connectTimeout,
                receiveTimeout: ApiEndpoints.receiveTimeout,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  // Zero Caching Policy: Always fetch fresh state directly from server
                  'Cache-Control': 'no-cache, no-store, must-revalidate',
                  'Pragma': 'no-cache',
                  'Expires': '0',
                },
              ),
            ) {
    _setupInterceptors();
  }

  final Dio _dio;
  final TokenStorageService _tokenStorage;
  bool _isRefreshing = false;

  Dio get rawDio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach Authorization Bearer token from secure storage if present
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          debugPrint('🌐 [API REQ] ${options.method} -> ${options.uri}');
          if (options.data != null) {
            try {
              final bodyStr = options.data is Map || options.data is List
                  ? jsonEncode(options.data)
                  : options.data.toString();
              debugPrint('📦 [API REQ BODY] $bodyStr');
            } catch (_) {
              debugPrint('📦 [API REQ BODY] ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '✅ [API RES] ${response.statusCode} <- ${response.requestOptions.method} ${response.requestOptions.uri}',
          );
          if (response.data != null) {
            try {
              final resStr = response.data is Map || response.data is List
                  ? jsonEncode(response.data)
                  : response.data.toString();
              // Print up to 1000 chars to avoid console truncation
              final preview = resStr.length > 1000 ? '${resStr.substring(0, 1000)}... (truncated)' : resStr;
              debugPrint('📄 [API RES DATA] $preview');
            } catch (_) {
              debugPrint('📄 [API RES DATA] ${response.data}');
            }
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          debugPrint(
            '❌ [API ERR] ${error.response?.statusCode ?? 'NO_STATUS'} <- ${error.requestOptions.method} ${error.requestOptions.uri} | Message: ${error.message}',
          );

          if (error.response?.data != null) {
            debugPrint('⚠️ [API ERR DATA] ${error.response?.data}');
          }

          final isAuthEndpoint = error.requestOptions.path.contains('/auth/login') ||
              error.requestOptions.path.contains('/auth/refresh-token');

          // Handle 401 Unauthorized with Automatic Silent Token Refresh in Background
          if (error.response?.statusCode == 401 && !isAuthEndpoint && !_isRefreshing) {
            _isRefreshing = true;
            debugPrint('🔄 [TOKEN REFRESH] Received 401 Unauthorized. Attempting background token refresh...');
            try {
              final refreshToken = await _tokenStorage.getRefreshToken();
              if (refreshToken != null && refreshToken.isNotEmpty) {
                // Call live /auth/refresh-token
                final refreshResponse = await _dio.post(
                  ApiEndpoints.refreshToken,
                  data: {'refreshToken': refreshToken},
                  options: Options(headers: {'Authorization': null}),
                );

                if (refreshResponse.statusCode == 200) {
                  final data = refreshResponse.data['data'] as Map<String, dynamic>;
                  final newToken = data['token'] as String? ?? '';
                  final newRefreshToken = data['refreshToken'] as String? ?? '';

                  if (newToken.isNotEmpty) {
                    await _tokenStorage.saveAccessToken(newToken);
                    if (newRefreshToken.isNotEmpty) {
                      await _tokenStorage.saveRefreshToken(newRefreshToken);
                    }

                    debugPrint('🎉 [TOKEN REFRESH SUCCESS] Successfully refreshed access token! Retrying original request...');

                    // Retry original request seamlessly with the newly acquired token
                    final originalOptions = error.requestOptions;
                    originalOptions.headers['Authorization'] = 'Bearer $newToken';

                    _isRefreshing = false;
                    final retryResponse = await _dio.fetch(originalOptions);
                    return handler.resolve(retryResponse);
                  }
                }
              } else {
                debugPrint('⚠️ [TOKEN REFRESH] No refresh token found in storage.');
              }
            } catch (refreshErr) {
              debugPrint('🚨 [TOKEN REFRESH FAILED] Error refreshing token: $refreshErr');
              await _tokenStorage.clearAll();
            } finally {
              _isRefreshing = false;
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // ── GET (No Cache) ────────────────────────────────────────────────
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ── POST ──────────────────────────────────────────────────────────
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ── PUT ───────────────────────────────────────────────────────────
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ── PATCH ─────────────────────────────────────────────────────────
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ── DELETE ────────────────────────────────────────────────────────
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
