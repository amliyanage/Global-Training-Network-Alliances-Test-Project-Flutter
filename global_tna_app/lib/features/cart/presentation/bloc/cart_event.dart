import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

class LoadCartEvent extends CartEvent {}

class AddCartItemEvent extends CartEvent {
  final String serviceId;
  final String slotId;
  final String bookingDate;
  final int quantity;

  const AddCartItemEvent(this.serviceId, this.slotId, this.bookingDate, this.quantity);

  @override
  List<Object> get props => [serviceId, slotId, bookingDate, quantity];
}

class UpdateCartItemEvent extends CartEvent {
  final String itemId;
  final int quantity;

  const UpdateCartItemEvent(this.itemId, this.quantity);

  @override
  List<Object> get props => [itemId, quantity];
}

class RemoveCartItemEvent extends CartEvent {
  final String itemId;

  const RemoveCartItemEvent(this.itemId);

  @override
  List<Object> get props => [itemId];
}
