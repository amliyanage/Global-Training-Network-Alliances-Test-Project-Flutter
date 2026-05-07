import 'package:equatable/equatable.dart';
import '../../../cart/domain/entities/cart_item.dart';
import 'payment_session.dart';

class BookingEntity extends Equatable {
  final String id;
  final String status; // pending, confirmed, completed, cancelled, failed
  final double totalAmount;
  final String paymentStatus;
  final String createdAt;
  final List<CartItemEntity> items;
  final PaymentSession? paymentSession;

  const BookingEntity({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.paymentStatus,
    required this.createdAt,
    required this.items,
    this.paymentSession,
  });

  @override
  List<Object?> get props =>
      [id, status, totalAmount, paymentStatus, createdAt, items, paymentSession];
}
