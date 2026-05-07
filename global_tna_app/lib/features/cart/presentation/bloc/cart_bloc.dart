import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/cart_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository repository;

  CartBloc({required this.repository}) : super(CartInitial()) {
    on<LoadCartEvent>(_onLoadCart);
    on<AddCartItemEvent>(_onAddItem);
    on<UpdateCartItemEvent>(_onUpdateItem);
    on<RemoveCartItemEvent>(_onRemoveItem);
  }

  Future<void> _onLoadCart(LoadCartEvent event, Emitter<CartState> emit) async {
    emit(CartLoading());
    final result = await repository.getCart();
    result.fold(
      (failure) => emit(CartError(failure.message)),
      (cart) => emit(CartLoaded(cart)),
    );
  }

  Future<void> _onAddItem(AddCartItemEvent event, Emitter<CartState> emit) async {
    emit(CartLoading());
    final result = await repository.addItem(
      event.serviceId,
      event.slotId,
      event.bookingDate,
      event.quantity,
    );
    result.fold(
      (failure) => emit(CartError(failure.message)),
      (cart) => emit(CartLoaded(cart)),
    );
  }

  Future<void> _onUpdateItem(UpdateCartItemEvent event, Emitter<CartState> emit) async {
    emit(CartLoading());
    final result = await repository.updateItem(event.itemId, event.quantity);
    result.fold(
      (failure) => emit(CartError(failure.message)),
      (cart) => emit(CartLoaded(cart)),
    );
  }

  Future<void> _onRemoveItem(RemoveCartItemEvent event, Emitter<CartState> emit) async {
    emit(CartLoading());
    final result = await repository.removeItem(event.itemId);
    result.fold(
      (failure) => emit(CartError(failure.message)),
      (cart) => emit(CartLoaded(cart)),
    );
  }
}
