class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final String? requestId;

  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.requestId,
  });

  @override
  String toString() => 'ApiException [$code] ($statusCode): $message (Req: $requestId)';

  factory ApiException.fromDioError({
    required dynamic error,
    int? statusCode,
  }) {
    if (error is Map<String, dynamic>) {
      final errObj = error['error'];
      if (errObj is Map<String, dynamic>) {
        return ApiException(
          code: errObj['code']?.toString() ?? 'API_ERROR',
          message: errObj['message']?.toString() ?? 'Terjadi kesalahan pada server.',
          statusCode: statusCode,
          requestId: error['requestId']?.toString(),
        );
      } else if (errObj is String) {
        return ApiException(
          code: 'API_ERROR',
          message: errObj,
          statusCode: statusCode,
          requestId: error['requestId']?.toString(),
        );
      }
    }

    return ApiException(
      code: 'NETWORK_ERROR',
      message: 'Tidak dapat terhubung ke server Armada API. Periksa koneksi internet Anda.',
      statusCode: statusCode,
    );
  }
}
