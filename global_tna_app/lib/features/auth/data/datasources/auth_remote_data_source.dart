import 'package:dio/dio.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../models/user_model.dart';
import '../../../../core/network/dio_client.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> signup(String email, String password);
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await dioClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      // Assuming the backend returns { "user": {id, email}, "token": "jwt_token" }
      // The token will be saved via the repository
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data['message'] ?? 'Login failed');
    }
  }

  @override
  Future<UserModel> signup(String email, String password) async {
    try {
      final response = await dioClient.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
      });
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data['message'] ?? 'Signup failed');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dioClient.dio.get('/auth/me');
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data['message'] ?? 'Failed to get current user');
    }
  }
}
