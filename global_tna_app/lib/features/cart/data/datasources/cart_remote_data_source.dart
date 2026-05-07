import 'package:dio/dio.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../models/cart_model.dart';
import '../../../../core/network/dio_client.dart';

abstract class CartRemoteDataSource {
  Future<CartModel> getCart();
  Future<CartModel> addItem(String serviceId, String slotId, String bookingDate, int quantity);
  Future<CartModel> updateItem(String itemId, int quantity);
  Future<CartModel> removeItem(String itemId);
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final DioClient dioClient;

  CartRemoteDataSourceImpl({required this.dioClient});

  String _extractErrorMessage(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = map['message'] ?? map['error'] ?? map['detail'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      if (message is List && message.isNotEmpty) {
        return message.join(', ');
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return fallback;
  }

  @override
  Future<CartModel> getCart() async {
    try {
      final response = await dioClient.dio.get('/cart');
      return CartModel.fromJson(response.data['cart'] ?? response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: _extractErrorMessage(e, 'Failed to load cart'),
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
      return CartModel.fromJson(response.data['cart'] ?? response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: _extractErrorMessage(
          e,
          'Failed to add item. Verify slotId and quantity.',
        ),
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
      return CartModel.fromJson(response.data['cart'] ?? response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: _extractErrorMessage(e, 'Failed to update item'),
      );
    }
  }

  @override
  Future<CartModel> removeItem(String itemId) async {
    try {
      final response = await dioClient.dio.delete('/cart/items/$itemId');
      return CartModel.fromJson(response.data['cart'] ?? response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: _extractErrorMessage(e, 'Failed to remove item'),
      );
    }
  }
}
