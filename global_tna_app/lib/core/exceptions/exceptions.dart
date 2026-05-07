class ServerException implements Exception {
  final String message;
  final String? errorCode;

  ServerException({required this.message, this.errorCode});
}

class CacheException implements Exception {
  final String message;

  CacheException({required this.message});
}
