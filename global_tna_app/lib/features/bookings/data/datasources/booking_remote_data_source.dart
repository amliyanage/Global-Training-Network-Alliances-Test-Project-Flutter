import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  String? _extractFirstStringFromList(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        final nested = _extractMessageFromMap(map);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  String? _extractMessageFromMap(Map<String, dynamic> map) {
    final messageValue = map['message'] ?? map['error'] ?? map['detail'];
    if (messageValue is String && messageValue.trim().isNotEmpty) {
      return messageValue.trim();
    }
    if (messageValue is List) {
      final text = _extractFirstStringFromList(messageValue);
      if (text != null) return text;
    }
    if (messageValue is Map) {
      final text = _extractMessageFromMap(
        Map<String, dynamic>.from(messageValue),
      );
      if (text != null) return text;
    }

    final errorsValue = map['errors'];
    if (errorsValue is List) {
      final text = _extractFirstStringFromList(errorsValue);
      if (text != null) return text;
    }
    if (errorsValue is Map) {
      final errorsMap = Map<String, dynamic>.from(errorsValue);
      for (final entry in errorsMap.entries) {
        final value = entry.value;
        if (value is String && value.trim().isNotEmpty) {
          return '${entry.key}: ${value.trim()}';
        }
        if (value is List) {
          final listText = _extractFirstStringFromList(value);
          if (listText != null) return '${entry.key}: $listText';
        }
      }
    }

    final dataValue = map['data'];
    if (dataValue is Map) {
      return _extractMessageFromMap(Map<String, dynamic>.from(dataValue));
    }

    return null;
  }

  String _extractErrorMessage(DioException e, String fallback) {
    final data = e.response?.data;

    if (kDebugMode) {
      debugPrint(
        '[BookingRemoteDataSource] API error '
        'status=${e.response?.statusCode} path=${e.requestOptions.path}',
      );
      debugPrint('[BookingRemoteDataSource] API error body: $data');
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = _extractMessageFromMap(map);
      if (message != null) {
        return message;
      }
    }

    if (data is List && data.isNotEmpty) {
      final message = _extractFirstStringFromList(data);
      if (message != null) {
        return message;
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    if (e.message != null && e.message!.trim().isNotEmpty) {
      return e.message!.trim();
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
    final Map<String, dynamic> body = {'paymentMethod': paymentMethod};
    if (customer.isNotEmpty) {
      body['customer'] = customer;
    }

    try {
      final response = await dioClient.dio.post(
        '/bookings/checkout',
        data: body,
      );

      if (kDebugMode) {
        debugPrint(
          '[BookingRemoteDataSource] checkout response: ${response.data}',
        );
      }

      if (response.data is Map) {
        return BookingModel.fromCheckoutJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      throw ServerException(message: 'Invalid checkout response format');
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[BookingRemoteDataSource] checkout request body: $body');
      }
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
        message: _extractErrorMessage(e, 'Failed to load bookings.'),
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
