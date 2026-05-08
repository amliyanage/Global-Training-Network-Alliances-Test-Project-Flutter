import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  final SharedPreferences sharedPreferences;
  static const _tokenKey = 'jwt_token';
  static const _cartCacheKey = 'cached_cart_v1';

  AuthInterceptor(this.sharedPreferences);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = sharedPreferences.getString(_tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Clear stale auth data globally when backend rejects the session token.
    if (err.response?.statusCode == 401) {
      sharedPreferences.remove(_tokenKey);
      sharedPreferences.remove(_cartCacheKey);
    }
    handler.next(err);
  }
}
