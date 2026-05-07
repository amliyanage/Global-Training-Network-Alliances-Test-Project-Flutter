import 'package:dio/dio.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../models/cart_model.dart';
import '../../../../core/network/dio_client.dart';

abstract class CartRemoteDataSource {
  Future<CartModel> getCart();
  Future<CartModel> addItem(
    String serviceId,
    String slotId,
    String bookingDate,
    int quantity,
  );
  Future<CartModel> updateItem(String itemId, int quantity);
  Future<CartModel> removeItem(String itemId);
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final DioClient dioClient;

  CartRemoteDataSourceImpl({required this.dioClient});

  Map<String, dynamic> _extractCartData(dynamic raw) {
    if (raw is Map) {
      final root = Map<String, dynamic>.from(raw);
      final nested = root['data'];
      if (nested is Map) {
        final dataMap = Map<String, dynamic>.from(nested);
        final cart = dataMap['cart'];
        if (cart is Map) return Map<String, dynamic>.from(cart);
        if (dataMap.containsKey('items') ||
            dataMap.containsKey('runningTotal')) {
          return dataMap;
        }
      }
      final cart = root['cart'];
      if (cart is Map) return Map<String, dynamic>.from(cart);
      return root;
    }
    return const {};
  }

  @override
  Future<CartModel> getCart() async {
    try {
      final response = await dioClient.dio.get('/cart');
      return CartModel.fromJson(_extractCartData(response.data));
    } on DioException catch (e) {
      throw ApiErrorMapper.mapDioException(
        e,
        fallbackMessage: 'Failed to load cart',
      );
    }
  }

  @override
  Future<CartModel> addItem(
    String serviceId,
    String slotId,
    String bookingDate,
    int quantity,
  ) async {
    try {
      final response = await dioClient.dio.post(
        '/cart/items',
        data: {
          'serviceId': serviceId,
          'slotId': slotId,
          'bookingDate': bookingDate,
          'quantity': quantity,
        },
      );
      return CartModel.fromJson(_extractCartData(response.data));
    } on DioException catch (e) {
      throw ApiErrorMapper.mapDioException(
        e,
        fallbackMessage: 'Failed to add item. Verify slot and quantity.',
      );
    }
  }

  @override
  Future<CartModel> updateItem(String itemId, int quantity) async {
    try {
      final response = await dioClient.dio.patch(
        '/cart/items/$itemId',
        data: {'quantity': quantity},
      );
      return CartModel.fromJson(_extractCartData(response.data));
    } on DioException catch (e) {
      throw ApiErrorMapper.mapDioException(
        e,
        fallbackMessage: 'Failed to update item',
      );
    }
  }

  @override
  Future<CartModel> removeItem(String itemId) async {
    try {
      final response = await dioClient.dio.delete('/cart/items/$itemId');
      return CartModel.fromJson(_extractCartData(response.data));
    } on DioException catch (e) {
      throw ApiErrorMapper.mapDioException(
        e,
        fallbackMessage: 'Failed to remove item',
      );
    }
  }
}
