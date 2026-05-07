import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/exceptions/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  static const String cachedTokenKey = 'jwt_token';

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final payload = await remoteDataSource.login(email, password);
      await sharedPreferences.setString(cachedTokenKey, payload.token);
      return Right(payload.user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.errorCode));
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }

  @override
  Future<Either<Failure, User>> signup(String email, String password) async {
    try {
      final payload = await remoteDataSource.signup(email, password);
      await sharedPreferences.setString(cachedTokenKey, payload.token);
      return Right(payload.user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.errorCode));
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
      return Left(ServerFailure(e.message, e.errorCode));
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await Future.wait([
        sharedPreferences.remove(cachedTokenKey),
        sharedPreferences.remove('cached_cart_v1'),
      ]);
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
