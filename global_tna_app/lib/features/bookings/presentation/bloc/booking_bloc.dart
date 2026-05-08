import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository repository;

  BookingBloc({required this.repository}) : super(BookingInitial()) {
    on<LoadBookingsEvent>(_onLoadBookings);
    on<LoadBookingByIdEvent>(_onLoadBookingById);
    on<CheckoutEvent>(_onCheckout);
    on<CancelBookingEvent>(_onCancelBooking);
  }

  Future<void> _onLoadBookings(
    LoadBookingsEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await repository.getBookings();
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (bookings) => emit(BookingsLoaded(bookings)),
    );
  }

  Future<void> _onLoadBookingById(
    LoadBookingByIdEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await repository.getBookingById(event.id);
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (booking) => emit(BookingDetailLoaded(booking)),
    );
  }

  Future<void> _onCheckout(
    CheckoutEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await repository.checkout(
      event.paymentMethod,
      event.customer,
    );
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (booking) => emit(BookingCheckoutSuccess(booking)),
    );
  }

  Future<void> _onCancelBooking(
    CancelBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await repository.cancelBooking(event.id);
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (booking) => add(LoadBookingsEvent()),
    );
  }
}
