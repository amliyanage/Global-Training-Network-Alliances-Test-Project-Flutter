import 'dart:convert';

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

  factory BookingModel.fromCheckoutJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final dataMap = _asMap(map['data']);
    final bookingMap = _resolveBookingMap(map, dataMap);
    final session = _extractPaymentSession(
      root: map,
      dataMap: dataMap,
      bookingMap: bookingMap,
    );

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
    if (value is String) {
      final normalized = value.replaceAll(',', '').trim();
      if (normalized.isEmpty) return null;
      return double.tryParse(normalized);
    }
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is String) {
      final raw = value.trim();
      if (raw.startsWith('{') && raw.endsWith('}')) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  static Map<String, dynamic> _resolveBookingMap(
    Map<String, dynamic> root,
    Map<String, dynamic>? dataMap,
  ) {
    final candidates = <Map<String, dynamic>?>[
      _asMap(root['booking']),
      _asMap(dataMap?['booking']),
      _asMap(dataMap?['data']),
      _asMap(root['data']),
      root,
    ];

    for (final candidate in candidates) {
      if (candidate == null || candidate.isEmpty) continue;
      if (_looksLikeBooking(candidate)) {
        return candidate;
      }
    }

    return root;
  }

  static bool _looksLikeBooking(Map<String, dynamic> map) {
    const bookingKeys = <String>{
      '_id',
      'id',
      'status',
      'totalAmount',
      'paymentStatus',
      'paymentMethod',
      'items',
      'paymentOrderId',
    };

    return map.keys.any(bookingKeys.contains);
  }

  static PaymentSession? _extractPaymentSession({
    required Map<String, dynamic> root,
    required Map<String, dynamic>? dataMap,
    required Map<String, dynamic> bookingMap,
  }) {
    final candidates = <dynamic>[
      root['paymentSession'],
      root['payment_session'],
      root['payhereSession'],
      root['payhere_session'],
      dataMap?['paymentSession'],
      dataMap?['payment_session'],
      dataMap?['payhereSession'],
      dataMap?['payhere_session'],
      bookingMap['paymentSession'],
      bookingMap['payment_session'],
      root['payload'],
      dataMap?['payload'],
    ];

    for (final candidate in candidates) {
      final session = _parsePaymentSession(
        rawSession: candidate,
        bookingMap: bookingMap,
      );
      if (session != null) return session;
    }

    return _buildFallbackSessionFromBooking(bookingMap);
  }

  static PaymentSession? _parsePaymentSession({
    required dynamic rawSession,
    required Map<String, dynamic> bookingMap,
  }) {
    final sessionMap = _asMap(rawSession);
    if (sessionMap == null) return null;

    final payloadCandidates = <Map<String, dynamic>>[
      if (_asMap(sessionMap['payload']) != null) _asMap(sessionMap['payload'])!,
      if (_asMap(sessionMap['data']) != null) _asMap(sessionMap['data'])!,
      if (_asMap(sessionMap['paymentPayload']) != null)
        _asMap(sessionMap['paymentPayload'])!,
      sessionMap,
    ];

    for (final payload in payloadCandidates) {
      final merchantId = _pickString(payload, const [
        'merchant_id',
        'merchantId',
      ]);
      final orderId =
          _pickString(payload, const [
            'order_id',
            'orderId',
            'payment_order_id',
            'paymentOrderId',
          ]) ??
          _pickString(bookingMap, const ['paymentOrderId', 'payment_order_id']);

      final amount =
          _pickDouble(payload, const [
            'amount',
            'payhere_amount',
            'payhereAmount',
            'totalAmount',
          ]) ??
          _pickDouble(bookingMap, const ['totalAmount', 'amount']);

      // If there are no payment session signals in this payload candidate,
      // skip quietly and keep trying the next candidate.
      final hasAnySignal =
          merchantId != null || orderId != null || amount != null;
      if (!hasAnySignal) {
        continue;
      }

      if (kDebugMode) {
        debugPrint(
          '[BookingModel] paymentSession payload keys: ${payload.keys.toList()}',
        );
      }

      // merchant_id can be omitted by backend; app can fill it from EnvConfig.
      if (orderId == null || amount == null || amount <= 0) {
        if (kDebugMode) {
          debugPrint(
            '[BookingModel] paymentSession candidate invalid: '
            'merchantId=$merchantId, orderId=$orderId, amount=$amount',
          );
        }
        continue;
      }

      return PaymentSession(
        merchantId: merchantId ?? '',
        orderId: orderId,
        amount: amount,
        currency:
            _pickString(payload, const ['currency', 'payhere_currency']) ??
            'LKR',
        notifyUrl:
            _pickString(payload, const ['notify_url', 'notifyUrl']) ?? '',
        returnUrl:
            _pickString(payload, const ['return_url', 'returnUrl']) ?? '',
        cancelUrl:
            _pickString(payload, const ['cancel_url', 'cancelUrl']) ?? '',
        custom1: _pickString(payload, const ['custom_1', 'custom1']) ?? '',
        custom2: _pickString(payload, const ['custom_2', 'custom2']) ?? '',
        sandbox: _pickBool(payload, const [
          'sandbox',
          'isSandbox',
        ], fallback: true),
      );
    }

    return null;
  }

  static PaymentSession? _buildFallbackSessionFromBooking(
    Map<String, dynamic> bookingMap,
  ) {
    final orderId = _pickString(bookingMap, const [
      'paymentOrderId',
      'payment_order_id',
      'orderId',
      'order_id',
      '_id',
      'id',
    ]);
    final amount = _pickDouble(bookingMap, const ['totalAmount', 'amount']);

    if (orderId == null || amount == null || amount <= 0) {
      return null;
    }

    if (kDebugMode) {
      debugPrint(
        '[BookingModel] building fallback paymentSession from booking fields '
        '(orderId=$orderId, amount=$amount)',
      );
    }

    return PaymentSession(
      // Kept empty on purpose; checkout page fills from EnvConfig when empty.
      merchantId:
          _pickString(bookingMap, const ['merchant_id', 'merchantId']) ?? '',
      orderId: orderId,
      amount: amount,
      currency:
          _pickString(bookingMap, const ['currency', 'payhere_currency']) ??
          'LKR',
      notifyUrl:
          _pickString(bookingMap, const ['notify_url', 'notifyUrl']) ?? '',
      returnUrl:
          _pickString(bookingMap, const ['return_url', 'returnUrl']) ?? '',
      cancelUrl:
          _pickString(bookingMap, const ['cancel_url', 'cancelUrl']) ?? '',
      custom1: _pickString(bookingMap, const ['_id', 'id', 'custom_1']) ?? '',
      custom2:
          _pickString(bookingMap, const ['userId', 'user_id', 'custom_2']) ??
          '',
      sandbox: _pickBool(bookingMap, const [
        'sandbox',
        'isSandbox',
      ], fallback: true),
    );
  }

  static String? _pickString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static double? _pickDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      final parsed = _asDouble(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static bool _pickBool(
    Map<String, dynamic> map,
    List<String> keys, {
    required bool fallback,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
    }
    return fallback;
  }
}
