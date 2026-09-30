import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

class DioClient {
  late final Dio _dio;
  final SecureStorageService _storageService;
  VoidCallback? onUnauthorized;

  DioClient({
    required SecureStorageService storageService,
    VoidCallback? onUnauthorized,
  })  : _storageService = storageService,
        onUnauthorized = onUnauthorized {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Client-Platform': AppConfig.clientPlatform,
          'X-Client-Version': AppConfig.appVersion,
        },
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach Bearer Token if available
          final token = await _storageService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            debugPrint('🌐 [DIO REQ] ${options.method} ${options.uri}');
            if (options.data != null) {
              debugPrint('📦 [DATA] ${options.data}');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('✅ [DIO RES ${response.statusCode}] ${response.realUri}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (kDebugMode) {
            debugPrint('❌ [DIO ERR ${e.response?.statusCode}] ${e.requestOptions.uri}: ${e.message}');
            if (e.response?.data != null) {
              debugPrint('🛑 [BODY] ${e.response?.data}');
            }
          }

          // Handle 401 Unauthorized
          if (e.response?.statusCode == 401) {
            debugPrint('🔒 401 Unauthorized detected. Clearing session.');
            await _storageService.clearSession();
            onUnauthorized?.call();
          }

          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  String _cleanPath(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }

  /// Helper to execute network request and wrap into standard data / ApiException
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        _cleanPath(path),
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(
        code: 'CLIENT_ERROR',
        message: 'Terjadi kesalahan lokal: $e',
      );
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        _cleanPath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(
        code: 'CLIENT_ERROR',
        message: 'Terjadi kesalahan lokal: $e',
      );
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        _cleanPath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(
        code: 'CLIENT_ERROR',
        message: 'Terjadi kesalahan lokal: $e',
      );
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        _cleanPath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(
        code: 'CLIENT_ERROR',
        message: 'Terjadi kesalahan lokal: $e',
      );
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      // Backend returns { success: true, data: ..., error: null, requestId: ... }
      if (map['success'] == false) {
        throw ApiException.fromDioError(
          error: map,
          statusCode: response.statusCode,
        );
      }
      return map;
    } else if (response.data is List) {
      return {'data': response.data, 'success': true};
    }
    return {'data': response.data, 'success': true};
  }

  ApiException _handleDioError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      return ApiException.fromDioError(
        error: e.response!.data,
        statusCode: e.response?.statusCode,
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException(
        code: 'TIMEOUT',
        message: 'Koneksi ke backend Armada timeout. Silakan coba lagi.',
        statusCode: 408,
      );
    }

    if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
      return ApiException(
        code: 'NETWORK_OFFLINE',
        message: 'Tidak dapat menghubungi server API. Pastikan internet aktif.',
        statusCode: 503,
      );
    }

    return ApiException(
      code: 'HTTP_${e.response?.statusCode ?? "UNKNOWN"}',
      message: e.message ?? 'Terjadi kesalahan pada koneksi API.',
      statusCode: e.response?.statusCode,
    );
  }
}
