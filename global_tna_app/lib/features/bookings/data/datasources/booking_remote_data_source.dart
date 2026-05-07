import 'package:dio/dio.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../models/booking_model.dart';
import '../../../../core/network/dio_client.dart';

abstract class BookingRemoteDataSource {
  Future<BookingModel> checkout(
    String paymentMethod,
    Map<String, String> customer,
  );
  Future<List<BookingModel>> getBookings();
  Future<BookingModel> getBookingById(String id);
  Future<BookingModel> cancelBooking(String id);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final DioClient dioClient;

  BookingRemoteDataSourceImpl({required this.dioClient});

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

  BookingModel _parseSingleBooking(dynamic body, {required String fallback}) {
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final rawBooking = map['booking'] ?? map['data'] ?? map;

      if (rawBooking is Map) {
        return BookingModel.fromJson(Map<String, dynamic>.from(rawBooking));
      }
    }

    throw ServerException(message: fallback);
  }

  List<BookingModel> _parseBookingList(dynamic body) {
    List<dynamic> rawList = const [];

    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final dynamic listData =
          map['data'] ?? map['bookings'] ?? map['items'] ?? const [];
      if (listData is List) {
        rawList = listData;
      } else {
        throw ServerException(message: 'Invalid bookings response format');
      }
    } else if (body is List) {
      rawList = body;
    } else {
      throw ServerException(message: 'Invalid bookings response format');
    }

    return rawList
        .map(
          (item) =>
              BookingModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<BookingModel> checkout(
    String paymentMethod,
    Map<String, String> customer,
  ) async {
    try {
      final Map<String, dynamic> body = {'paymentMethod': paymentMethod};
      if (customer.isNotEmpty) {
        body['customer'] = customer;
      }

      final response = await dioClient.dio.post(
        '/bookings/checkout',
        data: body,
      );

      if (response.data is Map) {
        return BookingModel.fromCheckoutJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      throw ServerException(message: 'Invalid checkout response format');
    } on DioException catch (e) {
      throw ServerException(
        message: _extractErrorMessage(e, 'Checkout failed'),
      );
    }
  }

  @override
  Future<List<BookingModel>> getBookings() async {
    try {
      final response = await dioClient.dio.get('/bookings');
      return _parseBookingList(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: _extractErrorMessage(
          e,
          'Failed to load bookings.',
        ),
      );
    }
  }

  @override
  Future<BookingModel> getBookingById(String id) async {
    try {
      final response = await dioClient.dio.get('/bookings/$id');
      return _parseSingleBooking(
        response.data,
        fallback: 'Invalid booking details response format',
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _extractErrorMessage(e, 'Failed to load booking details'),
      );
    }
  }

  @override
  Future<BookingModel> cancelBooking(String id) async {
    try {
      final response = await dioClient.dio.post('/bookings/$id/cancel');
      return _parseSingleBooking(
        response.data,
        fallback: 'Invalid cancel booking response format',
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _extractErrorMessage(e, 'Failed to cancel booking'),
      );
    }
  }
}
