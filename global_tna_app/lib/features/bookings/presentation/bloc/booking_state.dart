import 'package:equatable/equatable.dart';
import '../../domain/entities/booking.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingsLoaded extends BookingState {
  final List<BookingEntity> bookings;

  const BookingsLoaded(this.bookings);

  @override
  List<Object> get props => [bookings];
}

class BookingCheckoutSuccess extends BookingState {
  final BookingEntity booking;

  const BookingCheckoutSuccess(this.booking);

  @override
  List<Object> get props => [booking];
}

class BookingDetailLoaded extends BookingState {
  final BookingEntity booking;

  const BookingDetailLoaded(this.booking);

  @override
  List<Object> get props => [booking];
}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);

  @override
  List<Object> get props => [message];
}
