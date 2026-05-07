import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/exceptions/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;
  final DioClient dioClient; // added to extract token during login/signup

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPreferences,
    required this.dioClient,
  });

  static const String cachedTokenKey = 'jwt_token';

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final response = await dioClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final token = response.data['token'];
      if (token != null) {
        await sharedPreferences.setString(cachedTokenKey, token);
      }
      return Right(await remoteDataSource.getCurrentUser());
      // Wait, we can streamline this. Instead of calling getCurrentUser, 
      // let's adjust remoteDataSource or do it directly.
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on DioException catch (e) {
       return Left(ServerFailure(e.response?.data['message'] ?? "Login Failed"));
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }

  // Simplified signup
  @override
  Future<Either<Failure, User>> signup(String email, String password) async {
    try {
      final response = await dioClient.dio.post('/auth/signup', data: {
        'email': email,
        'password': password,
      });
      final token = response.data['token'];
      if (token != null) {
        await sharedPreferences.setString(cachedTokenKey, token);
      }
      return Right(await remoteDataSource.getCurrentUser());
    } on DioException catch (e) {
       return Left(ServerFailure(e.response?.data['message'] ?? "Signup Failed"));
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await sharedPreferences.remove(cachedTokenKey);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to clear cache'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = sharedPreferences.getString(cachedTokenKey);
    return token != null;
  }
}
