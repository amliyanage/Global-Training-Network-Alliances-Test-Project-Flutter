import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/cart_model.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository repository;
  final SharedPreferences sharedPreferences;
  static const _cacheKey = 'cached_cart_v1';

  CartBloc({required this.repository, required this.sharedPreferences})
    : super(CartInitial()) {
    on<LoadCartEvent>(_onLoadCart);
    on<AddCartItemEvent>(_onAddItem);
    on<UpdateCartItemEvent>(_onUpdateItem);
    on<RemoveCartItemEvent>(_onRemoveItem);
  }

  CartModel? _readCachedCart() {
    final raw = sharedPreferences.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return CartModel.fromJson(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> _cacheCart(CartModel cart) async {
    await sharedPreferences.setString(_cacheKey, jsonEncode(cart.toJson()));
  }

  CartModel _toCartModel(CartEntity cart) {
    final items = cart.items
        .map(
          (item) => CartItemModel(
            id: item.id,
            serviceId: item.serviceId,
            slotId: item.slotId,
            quantity: item.quantity,
            price: item.price,
            serviceName: item.serviceName,
          ),
        )
        .toList();
    return CartModel(
      id: cart.id,
      itemsModel: items,
      runningTotal: cart.runningTotal,
    );
  }

  Future<void> _onLoadCart(LoadCartEvent event, Emitter<CartState> emit) async {
    final cached = _readCachedCart();
    if (cached != null) {
      emit(CartLoaded(cached));
    } else {
      emit(CartLoading());
    }

    final result = await repository.getCart();
    await result.fold(
      (failure) async {
        emit(CartError(failure.message));
      },
      (cart) async {
        final model = _toCartModel(cart);
        await _cacheCart(model);
        emit(CartLoaded(model));
      },
    );
  }

  Future<void> _onAddItem(
    AddCartItemEvent event,
    Emitter<CartState> emit,
  ) async {
    emit(CartLoading());
    final result = await repository.addItem(
      event.serviceId,
      event.slotId,
      event.bookingDate,
      event.quantity,
    );
    await result.fold(
      (failure) async {
        emit(CartError(failure.message));
      },
      (cart) async {
        final model = _toCartModel(cart);
        await _cacheCart(model);
        emit(CartLoaded(model));
      },
    );
  }

  Future<void> _onUpdateItem(
    UpdateCartItemEvent event,
    Emitter<CartState> emit,
  ) async {
    emit(CartLoading());
    final result = await repository.updateItem(event.itemId, event.quantity);
    await result.fold(
      (failure) async {
        emit(CartError(failure.message));
      },
      (cart) async {
        final model = _toCartModel(cart);
        await _cacheCart(model);
        emit(CartLoaded(model));
      },
    );
  }

  Future<void> _onRemoveItem(
    RemoveCartItemEvent event,
    Emitter<CartState> emit,
  ) async {
    emit(CartLoading());
    final result = await repository.removeItem(event.itemId);
    await result.fold(
      (failure) async {
        emit(CartError(failure.message));
      },
      (cart) async {
        final model = _toCartModel(cart);
        await _cacheCart(model);
        emit(CartLoaded(model));
      },
    );
  }
}
