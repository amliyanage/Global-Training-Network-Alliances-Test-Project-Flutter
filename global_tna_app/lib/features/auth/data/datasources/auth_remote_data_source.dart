import 'package:dio/dio.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../models/user_model.dart';
import '../../../../core/network/dio_client.dart';

class AuthPayload {
  final UserModel user;
  final String token;

  const AuthPayload({required this.user, required this.token});
}

abstract class AuthRemoteDataSource {
  Future<AuthPayload> login(String email, String password);
  Future<AuthPayload> signup(String email, String password);
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<AuthPayload> login(String email, String password) async {
    try {
      final response = await dioClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return _parseAuthPayload(response.data);
    } on DioException catch (e) {
      throw ApiErrorMapper.mapDioException(e, fallbackMessage: 'Login failed');
    }
  }

  @override
  Future<AuthPayload> signup(String email, String password) async {
    try {
      final response = await dioClient.dio.post(
        '/auth/register',
        data: {'email': email, 'password': password},
      );
      return _parseAuthPayload(response.data);
    } on DioException catch (e) {
      throw ApiErrorMapper.mapDioException(e, fallbackMessage: 'Signup failed');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dioClient.dio.get('/auth/me');
      final data = _asMap(response.data);
      final nested = _asMap(data['data']);
      final topLevelUser = _asMap(data['user']);
      final nestedUser = _asMap(nested['user']);
      final userMap = topLevelUser.isNotEmpty
          ? topLevelUser
          : (nestedUser.isNotEmpty ? nestedUser : nested);
      return UserModel.fromJson(userMap);
    } on DioException catch (e) {
      throw ApiErrorMapper.mapDioException(
        e,
        fallbackMessage: 'Failed to get current user',
      );
    }
  }

  AuthPayload _parseAuthPayload(dynamic raw) {
    final root = _asMap(raw);
    final data = _asMap(root['data']);
    final topLevelUser = _asMap(root['user']);
    final nestedUser = _asMap(data['user']);
    final userMap = topLevelUser.isNotEmpty ? topLevelUser : nestedUser;
    final token = (root['token'] ?? data['token'] ?? data['accessToken'] ?? '')
        .toString();

    if (userMap.isEmpty || token.trim().isEmpty) {
      throw ServerException(
        message: 'Invalid authentication response from server',
        errorCode: 'INVALID_RESPONSE',
      );
    }

    return AuthPayload(user: UserModel.fromJson(userMap), token: token.trim());
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}
