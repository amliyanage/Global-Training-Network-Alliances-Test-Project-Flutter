import 'package:equatable/equatable.dart';

class CartItemEntity extends Equatable {
  final String id;
  final String serviceId;
  final String slotId;
  final int quantity;
  final double price; 
  final String serviceName;

  const CartItemEntity({
    required this.id,
    required this.serviceId,
    required this.slotId,
    required this.quantity,
    required this.price,
    required this.serviceName,
  });

  @override
  List<Object?> get props => [
    id,
    serviceId,
    slotId,
    quantity,
    price,
    serviceName,
  ];
}
