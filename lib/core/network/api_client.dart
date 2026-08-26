import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';
import 'token_storage_service.dart';

/// Centralized HTTP API Client with Zero-Caching Policy, Background Token Refresh, and Detailed Debug Logging
class ApiClient {
  ApiClient({Dio? dio, TokenStorageService? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorageService(),
      _dio =
          dio ??
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
  final List<Completer<String?>> _refreshQueue = [];

  Dio get rawDio => _dio;

  Future<String?> _performSilentTokenRefresh() async {
    if (_isRefreshing) {
      final completer = Completer<String?>();
      _refreshQueue.add(completer);
      return completer.future;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _flushQueue(null);
        return null;
      }

      // Use isolated Dio instance for token refresh to prevent log noise & recursion
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: ApiEndpoints.connectTimeout,
          receiveTimeout: ApiEndpoints.receiveTimeout,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        final newToken = data?['token'] as String? ?? '';
        final newRefreshToken = data?['refreshToken'] as String? ?? '';

        if (newToken.isNotEmpty) {
          await _tokenStorage.saveAccessToken(newToken);
          if (newRefreshToken.isNotEmpty) {
            await _tokenStorage.saveRefreshToken(newRefreshToken);
          }
          debugPrint(
            '🎉 [TOKEN REFRESH] Session token refreshed silently in background.',
          );
          _flushQueue(newToken);
          return newToken;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [TOKEN REFRESH FAILED] Session expired: $e');
      await _tokenStorage.clearAll();
    } finally {
      _isRefreshing = false;
    }

    _flushQueue(null);
    return null;
  }

  void _flushQueue(String? newToken) {
    for (final completer in _refreshQueue) {
      if (!completer.isCompleted) {
        completer.complete(newToken);
      }
    }
    _refreshQueue.clear();
  }

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
              final preview = resStr.length > 1000
                  ? '${resStr.substring(0, 1000)}... (truncated)'
                  : resStr;
              debugPrint('📄 [API RES DATA] $preview');
            } catch (_) {
              debugPrint('📄 [API RES DATA] ${response.data}');
            }
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          final statusCode = error.response?.statusCode ?? 'NO_STATUS';
          final path = error.requestOptions.path;
          final method = error.requestOptions.method;

          final isAuthEndpoint =
              error.requestOptions.path.contains('/auth/login') ||
              error.requestOptions.path.contains('/auth/refresh-token');

          // Handle 401 Unauthorized with Automatic Silent Token Refresh in Background
          if (error.response?.statusCode == 401 && !isAuthEndpoint) {
            debugPrint(
              '🔄 [TOKEN REFRESH] 401 Unauthorized on $method $path. Refreshing token silently...',
            );
            final newToken = await _performSilentTokenRefresh();
            if (newToken != null && newToken.isNotEmpty) {
              final originalOptions = error.requestOptions;
              originalOptions.headers['Authorization'] = 'Bearer $newToken';
              try {
                final retryResponse = await _dio.fetch(originalOptions);
                return handler.resolve(retryResponse);
              } catch (retryErr) {
                return handler.next(error);
              }
            }
          }

          debugPrint('❌ [API ERR] $statusCode <- $method $path');
          if (error.response?.data != null) {
            debugPrint('❌ [API ERR DATA] ${error.response?.data}');
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

  /// Uploads bytes to a presigned external URL without JWT interceptors.
  Future<Response<void>> putAbsoluteBytes(
    String url, {
    required Uint8List bytes,
    required String contentType,
  }) {
    final uploadDio = Dio();
    return uploadDio.putUri<void>(
      Uri.parse(url),
      data: bytes,
      options: Options(
        contentType: contentType,
        headers: {'Content-Length': bytes.length},
      ),
    );
  }

  /// Downloads bytes from a public or presigned external URL without adding
  /// the KaratFlow bearer token to the external host.
  Future<Uint8List> getAbsoluteBytes(String url) async {
    final downloadDio = Dio(
      BaseOptions(
        connectTimeout: ApiEndpoints.connectTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
      ),
    );
    final response = await downloadDio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('The downloaded audio file is empty.');
    }
    return Uint8List.fromList(bytes);
  }
}
