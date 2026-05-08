import 'package:equatable/equatable.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object> get props => [];
}

class LoadBookingsEvent extends BookingEvent {}

class CheckoutEvent extends BookingEvent {
  final String paymentMethod;
  final Map<String, String> customer;

  const CheckoutEvent({required this.paymentMethod, this.customer = const {}});

  @override
  List<Object> get props => [paymentMethod, customer];
}

class CancelBookingEvent extends BookingEvent {
  final String id;

  const CancelBookingEvent(this.id);

  @override
  List<Object> get props => [id];
}

class LoadBookingByIdEvent extends BookingEvent {
  final String id;

  const LoadBookingByIdEvent(this.id);

  @override
  List<Object> get props => [id];
}
