import 'package:flutter/foundation.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/payment_session.dart';
import '../../../cart/data/models/cart_item_model.dart';

class BookingModel extends BookingEntity {
  final List<CartItemModel> itemsModel;

  const BookingModel({
    required super.id,
    required super.status,
    required super.totalAmount,
    required super.paymentStatus,
    required super.createdAt,
    required this.itemsModel,
    super.paymentSession,
  }) : super(items: itemsModel);

  factory BookingModel.fromJson(
    Map<String, dynamic> json, {
    PaymentSession? paymentSession,
  }) {
    final map = Map<String, dynamic>.from(json);
    final rawItems = map['items'];

    final items = <CartItemModel>[];
    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is Map) {
          items.add(CartItemModel.fromJson(Map<String, dynamic>.from(rawItem)));
        }
      }
    }

    return BookingModel(
      id: (map['_id'] ?? map['id'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      totalAmount: _asDouble(map['totalAmount']) ?? 0,
      paymentStatus: (map['paymentStatus'] ?? map['paymentMethod'] ?? 'unknown')
          .toString(),
      createdAt: (map['createdAt'] ?? '').toString(),
      itemsModel: items,
      paymentSession: paymentSession,
    );
  }

  /// Parses a full checkout API response body that may contain a nested
  /// `paymentSession.payload` object alongside the booking data.
  ///
  /// Supports multiple response shapes:
  ///   Shape A: { booking: {...}, paymentSession: { payload: {...} } }
  ///   Shape B: { data: { booking: {...} }, paymentSession: { payload: {...} } }
  ///   Shape C: { _id: ..., paymentSession: { payload: {...} } }   (flat)
  factory BookingModel.fromCheckoutJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);

    // ── 1. Locate booking data ──────────────────────────────────────────
    Map<String, dynamic> bookingMap;
    final rawBookingOrData = map['booking'] ?? map['data'];
    if (rawBookingOrData is Map) {
      // Could be { booking: { ... } } OR { data: { booking: { ... } } }
      final inner = rawBookingOrData;
      final nested = inner['booking'];
      if (nested is Map) {
        bookingMap = Map<String, dynamic>.from(nested);
      } else {
        bookingMap = Map<String, dynamic>.from(inner);
      }
    } else {
      // Flat response — the root IS the booking
      bookingMap = map;
    }

    // ── 2. Locate paymentSession ────────────────────────────────────────
    // Try root level first, then inside booking wrapper
    dynamic rawSession = map['paymentSession'];
    if (rawSession == null) {
      final wrapper = map['booking'] ?? map['data'];
      if (wrapper is Map) rawSession = wrapper['paymentSession'];
    }

    PaymentSession? session;
    if (rawSession is Map) {
      final sessionMap = Map<String, dynamic>.from(rawSession);
      // Payload may be directly in paymentSession or nested under 'payload'
      final rawPayload = sessionMap['payload'] ?? sessionMap;
      if (rawPayload is Map) {
        final payload = Map<String, dynamic>.from(rawPayload);

        // Log in debug mode to help diagnose issues
        if (kDebugMode) {
          debugPrint('[BookingModel] paymentSession payload: $payload');
        }

        final merchantId = (payload['merchant_id'] ?? '').toString();
        final orderId = (payload['order_id'] ?? '').toString();
        final amount = _asDouble(payload['amount']) ?? 0.0;

        // Only build a valid session if the mandatory fields are present
        if (merchantId.isNotEmpty && orderId.isNotEmpty && amount > 0) {
          session = PaymentSession(
            merchantId: merchantId,
            orderId: orderId,
            amount: amount,
            currency: (payload['currency'] ?? 'LKR').toString(),
            notifyUrl: (payload['notify_url'] ?? '').toString(),
            returnUrl: (payload['return_url'] ?? '').toString(),
            cancelUrl: (payload['cancel_url'] ?? '').toString(),
            custom1: (payload['custom_1'] ?? '').toString(),
            custom2: (payload['custom_2'] ?? '').toString(),
            // Default to SANDBOX mode — backend should explicitly set false for live
            sandbox: payload['sandbox'] != false,
          );
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[BookingModel] fromCheckoutJson → session=${session != null ? "found (orderId=${session.orderId}, sandbox=${session.sandbox})" : "NULL — paymentSession missing or invalid in response"}',
      );
    }

    return BookingModel.fromJson(bookingMap, paymentSession: session);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'status': status,
        'totalAmount': totalAmount,
        'paymentStatus': paymentStatus,
        'createdAt': createdAt,
        'items': itemsModel.map((e) => e.toJson()).toList(),
      };

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
