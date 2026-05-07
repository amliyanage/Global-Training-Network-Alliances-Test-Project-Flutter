import '../../domain/entities/cart.dart';
import 'cart_item_model.dart';

class CartModel extends CartEntity {
  final List<CartItemModel> itemsModel;

  const CartModel({
    required super.id,
    required this.itemsModel,
    required super.runningTotal,
  }) : super(items: itemsModel);

  factory CartModel.fromJson(Map<String, dynamic> json) {
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

    final providedTotal =
        _asDouble(map['runningTotal']) ??
        _asDouble(map['total']) ??
        _asDouble(map['totalAmount']);

    final computedTotal = items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return CartModel(
      id: (map['_id'] ?? map['id'] ?? '').toString(),
      itemsModel: items,
      runningTotal: providedTotal ?? computedTotal,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'runningTotal': runningTotal,
    'items': itemsModel.map((e) => e.toJson()).toList(),
  };

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
