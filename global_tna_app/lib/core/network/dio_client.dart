import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/env_config.dart';
import 'auth_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  final Dio dio;

  DioClient({required SharedPreferences sharedPreferences})
    : dio = Dio(
        BaseOptions(
          baseUrl: EnvConfig.apiUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ) {
    dio.interceptors.add(AuthInterceptor(sharedPreferences));
    if (kDebugMode) {
      debugPrint('Dio base URL: ${dio.options.baseUrl}');
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (message) =>
              debugPrint(message.toString(), wrapWidth: 1024),
        ),
      );
    }
  }
}
