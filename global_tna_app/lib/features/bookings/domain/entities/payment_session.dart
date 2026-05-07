import 'package:equatable/equatable.dart';

/// Holds the PayHere payment session data returned from the checkout endpoint.
class PaymentSession extends Equatable {
  final String merchantId;
  final String orderId;
  final double amount;
  final String currency;
  final String notifyUrl;
  final String returnUrl;
  final String cancelUrl;
  final String custom1; // bookingId
  final String custom2; // userId
  final bool sandbox;

  const PaymentSession({
    required this.merchantId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.notifyUrl,
    required this.returnUrl,
    required this.cancelUrl,
    required this.custom1,
    required this.custom2,
    required this.sandbox,
  });

  @override
  List<Object?> get props => [
        merchantId,
        orderId,
        amount,
        currency,
        notifyUrl,
        returnUrl,
        cancelUrl,
        custom1,
        custom2,
        sandbox,
      ];
}
