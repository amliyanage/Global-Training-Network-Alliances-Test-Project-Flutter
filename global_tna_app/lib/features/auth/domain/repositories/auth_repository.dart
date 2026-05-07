import 'package:dartz/dartz.dart';
import '../../../../core/exceptions/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> signup(String email, String password);
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, void>> logout();
  Future<bool> isLoggedIn();
}
