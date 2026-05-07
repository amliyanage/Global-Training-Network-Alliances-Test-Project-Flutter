import 'package:equatable/equatable.dart';
class PaymentSession extends Equatable {
  final String merchantId;
  final String orderId;
  final double amount;
  final String currency;
  final String notifyUrl;
  final String returnUrl;
  final String cancelUrl;
  final String custom1; 
  final String custom2;
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
