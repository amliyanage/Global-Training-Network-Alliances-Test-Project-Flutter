import 'package:dartz/dartz.dart';
import '../../../../core/exceptions/failures.dart';
import '../entities/cart.dart';

abstract class CartRepository {
  Future<Either<Failure, CartEntity>> getCart();
  Future<Either<Failure, CartEntity>> addItem(
    String serviceId,
    String slotId,
    String bookingDate,
    int quantity,
  );
  Future<Either<Failure, CartEntity>> updateItem(String itemId, int quantity);
  Future<Either<Failure, CartEntity>> removeItem(String itemId);
}
