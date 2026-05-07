import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  final SharedPreferences sharedPreferences;

  AuthInterceptor(this.sharedPreferences);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = sharedPreferences.getString('jwt_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // If the server returns 401 Unauthorized, we can handle it globally here
    if (err.response?.statusCode == 401) {
      // Potentially trigger a global logout event or token refresh depending on backend support
    }
    super.onError(err, handler);
  }
}
