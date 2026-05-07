import 'package:dartz/dartz.dart';
import '../../../../core/exceptions/failures.dart';
import '../entities/booking.dart';

abstract class BookingRepository {
  Future<Either<Failure, BookingEntity>> checkout(
    String paymentMethod,
    Map<String, String> customer,
  );
  Future<Either<Failure, List<BookingEntity>>> getBookings();
  Future<Either<Failure, BookingEntity>> getBookingById(String id);
  Future<Either<Failure, BookingEntity>> cancelBooking(String id);
}
