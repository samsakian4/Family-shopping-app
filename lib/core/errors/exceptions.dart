/// Data-layer exceptions. Repositories catch these and map them to a
/// [Failure] before returning to the domain/application layer.
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Authentication error']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Local database error']);
}
