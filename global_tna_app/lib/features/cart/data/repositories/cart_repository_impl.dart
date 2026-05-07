import 'package:dartz/dartz.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/exceptions/failures.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_data_source.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource remoteDataSource;

  CartRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, CartEntity>> getCart() async {
    try {
      final cart = await remoteDataSource.getCart();
      return Right(cart);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on TypeError {
      return const Left(ServerFailure('Invalid cart data format from API'));
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }

  @override
  Future<Either<Failure, CartEntity>> addItem(
    String serviceId,
    String slotId,
    String bookingDate,
    int quantity,
  ) async {
    try {
      final cart = await remoteDataSource.addItem(serviceId, slotId, bookingDate, quantity);
      return Right(cart);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on TypeError {
      return const Left(
        ServerFailure('Invalid cart item response format from API'),
      );
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }

  @override
  Future<Either<Failure, CartEntity>> updateItem(
    String itemId,
    int quantity,
  ) async {
    try {
      final cart = await remoteDataSource.updateItem(itemId, quantity);
      return Right(cart);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on TypeError {
      return const Left(
        ServerFailure('Invalid cart update response format from API'),
      );
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }

  @override
  Future<Either<Failure, CartEntity>> removeItem(String itemId) async {
    try {
      final cart = await remoteDataSource.removeItem(itemId);
      return Right(cart);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on TypeError {
      return const Left(
        ServerFailure('Invalid cart remove response format from API'),
      );
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }
}
