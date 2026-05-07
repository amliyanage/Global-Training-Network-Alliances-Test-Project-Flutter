import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class CartEntity extends Equatable {
  final String id;
  final List<CartItemEntity> items;
  final double runningTotal;

  const CartEntity({
    required this.id,
    required this.items,
    required this.runningTotal,
  });

  @override
  List<Object?> get props => [id, items, runningTotal];
}
