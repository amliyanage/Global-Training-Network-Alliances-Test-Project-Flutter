import 'package:dartz/dartz.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/exceptions/failures.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_data_source.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, BookingEntity>> checkout(
    String paymentMethod,
    Map<String, String> customer,
  ) async {
    try {
      final booking = await remoteDataSource.checkout(paymentMethod, customer);
      return Right(booking);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.errorCode));
    } on TypeError {
      return const Left(
        ServerFailure('Invalid checkout response format from API'),
      );
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> getBookings() async {
    try {
      final bookings = await remoteDataSource.getBookings();
      return Right(bookings);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.errorCode));
    } on TypeError {
      return const Left(
        ServerFailure('Invalid bookings response format from API'),
      );
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> getBookingById(String id) async {
    try {
      final booking = await remoteDataSource.getBookingById(id);
      return Right(booking);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.errorCode));
    } on TypeError {
      return const Left(
        ServerFailure('Invalid booking details response format from API'),
      );
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> cancelBooking(String id) async {
    try {
      final booking = await remoteDataSource.cancelBooking(id);
      return Right(booking);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.errorCode));
    } on TypeError {
      return const Left(
        ServerFailure('Invalid cancel booking response format from API'),
      );
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }
}
