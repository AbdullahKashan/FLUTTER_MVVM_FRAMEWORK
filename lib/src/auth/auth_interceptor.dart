import 'dart:async';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../network/interceptor.dart';
import 'auth_manager.dart';

/// Interceptor that attaches JWT Bearer tokens to outgoing requests and automatically
/// performs token refresh and retry when an HTTP 401 Unauthorized occurs.
class AuthInterceptor extends Interceptor {
  final AuthManager authManager;
  final ApiClient Function() clientProvider;

  AuthInterceptor({
    required this.authManager,
    required this.clientProvider,
  });

  @override
  FutureOr<RequestOptions> onRequest(RequestOptions options) {
    final token = authManager.tokenManager.accessToken;
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return options;
  }

  @override
  FutureOr<dynamic> onError(ApiException error) async {
    if (error is UnauthorizedException && authManager.isAuthenticated) {
      try {
        final newToken = await authManager.refreshToken();
        final client = clientProvider();
        return await client.get<dynamic>(
          '',
          headers: {'Authorization': 'Bearer $newToken'},
        );
      } catch (_) {
        return error;
      }
    }
    return error;
  }
}
