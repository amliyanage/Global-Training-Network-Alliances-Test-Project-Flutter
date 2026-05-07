import '../../domain/entities/cart_item.dart';

class CartItemModel extends CartItemEntity {
  const CartItemModel({
    required super.id,
    required super.serviceId,
    required super.slotId,
    required super.quantity,
    required super.price,
    required super.serviceName,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);

    final dynamic rawService = map['serviceId'] ?? map['service'];
    String serviceId = '';
    String serviceName = '';
    double price = _asDouble(map['price'] ?? map['priceSnapshot']);

    if (rawService is String) {
      serviceId = rawService;
    } else if (rawService is Map) {
      final serviceMap = Map<String, dynamic>.from(rawService);
      serviceId = (serviceMap['_id'] ?? serviceMap['id'] ?? '').toString();
      final dynamic rawName = serviceMap['title'] ?? serviceMap['name'];
      if (rawName is String) {
        serviceName = rawName;
      }
      if (price == 0) {
        price = _asDouble(serviceMap['price']);
      }
    }

    final dynamic rawSlot = map['slotId'];
    String slotId = '';
    if (rawSlot is String) {
      slotId = rawSlot;
    } else if (rawSlot is Map) {
      final slotMap = Map<String, dynamic>.from(rawSlot);
      slotId = (slotMap['_id'] ?? slotMap['id'] ?? '').toString();
    }

    final dynamic explicitName = map['serviceName'];
    if (explicitName is String && explicitName.trim().isNotEmpty) {
      serviceName = explicitName.trim();
    }

    return CartItemModel(
      id: (map['_id'] ?? map['id'] ?? '').toString(),
      serviceId: serviceId,
      slotId: slotId,
      quantity: _asInt(map['quantity'], fallback: 1),
      price: price,
      serviceName: serviceName.isEmpty ? 'Service' : serviceName,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'serviceId': serviceId,
    'slotId': slotId,
    'quantity': quantity,
    'price': price,
    'serviceName': serviceName,
  };

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
