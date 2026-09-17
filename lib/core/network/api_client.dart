import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'token_storage_service.dart';

/// Centralized HTTP API Client with Zero-Caching Policy and Background Token Refresh.
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

      // Use isolated Dio instance for token refresh to prevent interceptor recursion
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
        final newToken =
            (data?['token'] ?? data?['accessToken']) as String? ?? '';
        final newRefreshToken =
            (data?['refreshToken'] ?? data?['refresh_token']) as String? ?? '';

        if (newToken.isNotEmpty) {
          await _tokenStorage.saveAccessToken(newToken);
          if (newRefreshToken.isNotEmpty) {
            await _tokenStorage.saveRefreshToken(newRefreshToken);
          }
          _flushQueue(newToken);
          return newToken;
        }
      }
    } catch (e) {
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

          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isAuthEndpoint =
              error.requestOptions.path.contains('/auth/login') ||
              error.requestOptions.path.contains('/auth/refresh-token');

          // Handle 401 Unauthorized with Automatic Silent Token Refresh in Background
          if (error.response?.statusCode == 401 && !isAuthEndpoint) {
            final storedRefreshToken = await _tokenStorage.getRefreshToken();
            if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
              return handler.next(error);
            }
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
  /// the KaratFlow bearer token to the external host. If an internal Karatflow URL
  /// is passed, automatically delegates to [getBytes] with Bearer auth.
  Future<Uint8List> getAbsoluteBytes(String url) async {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://') ||
        (uri != null && uri.host.toLowerCase().contains('scalesutra.com'))) {
      return getBytes(trimmed);
    }

    final downloadDio = Dio(
      BaseOptions(
        connectTimeout: ApiEndpoints.connectTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
      ),
    );
    final response = await downloadDio.get<List<int>>(
      trimmed,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('The downloaded file is empty.');
    }
    return Uint8List.fromList(bytes);
  }

  /// Downloads bytes with automatic authentication detection:
  /// - KaratFlow internal routes (/api/..., scalesutra.com) are requested with JWT Bearer auth.
  /// - External URLs (AWS S3, Cloudflare R2 presigned URLs) are requested without extra auth headers.
  Future<Uint8List> getBytes(String urlOrPath) async {
    final trimmed = urlOrPath.trim();
    final uri = Uri.tryParse(trimmed);
    final isHttp =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');
    final isInternal =
        !isHttp ||
        (uri != null &&
            (uri.host.toLowerCase().contains('scalesutra.com') ||
                uri.host.toLowerCase().contains('134.195.138.153') ||
                uri.host.toLowerCase().contains('localhost')));

    if (isInternal) {
      final token = await _tokenStorage.getAccessToken();
      final headers = <String, dynamic>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      String cleanPath = trimmed;
      if (cleanPath.startsWith('/storage/')) {
        cleanPath = '/api/v1$cleanPath';
      } else if (cleanPath.startsWith('storage/')) {
        cleanPath = '/api/v1/$cleanPath';
      }

      final fullUrl = isHttp
          ? trimmed
          : (cleanPath.startsWith('/api/')
                ? Uri.parse(ApiEndpoints.baseUrl)
                      .replace(
                        path: cleanPath.split('?')[0],
                        query: cleanPath.contains('?')
                            ? cleanPath.substring(cleanPath.indexOf('?') + 1)
                            : null,
                      )
                      .toString()
                : Uri.parse(
                    ApiEndpoints.baseUrl,
                  ).resolve(cleanPath).toString());

      final downloadDio = Dio(
        BaseOptions(
          connectTimeout: ApiEndpoints.connectTimeout,
          receiveTimeout: ApiEndpoints.receiveTimeout,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final response = await downloadDio.get<List<int>>(
        fullUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers.isNotEmpty ? headers : null,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Handle 301, 302, 303, 307, 308 redirect WITHOUT Authorization header
      if (response.statusCode != null &&
          response.statusCode! >= 300 &&
          response.statusCode! < 400) {
        final redirectLocation = response.headers.value('location');
        if (redirectLocation != null && redirectLocation.trim().isNotEmpty) {
          final resolvedLocation = Uri.parse(
            fullUrl,
          ).resolve(redirectLocation.trim()).toString();
          return getAbsoluteBytes(resolvedLocation);
        }
      }

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('Empty payload received from server.');
      }
      return Uint8List.fromList(bytes);
    } else {
      return getAbsoluteBytes(trimmed);
    }
  }
}
