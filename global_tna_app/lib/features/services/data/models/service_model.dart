import '../../domain/entities/service.dart';
import '../../domain/entities/service_slot.dart';

class ServiceSlotModel extends ServiceSlotEntity {
  const ServiceSlotModel({
    required super.id,
    required super.startTime,
    required super.capacity,
    super.reserved,
  });

  factory ServiceSlotModel.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final rawCapacity =
        _asInt(map['capacity']) ??
        _asInt(map['capacityPerSlot']) ??
        _asInt(map['maxCapacity']) ??
        0;
    final rawReserved =
        _asInt(map['reserved']) ??
        _asInt(map['booked']) ??
        _asInt(map['bookedCount']) ??
        0;

    final parsedStart =
        DateTime.tryParse(
          (map['startTime'] ?? map['start'] ?? '').toString(),
        ) ??
        DateTime.now().toUtc();

    return ServiceSlotModel(
      id: (map['_id'] ?? map['id'] ?? '').toString(),
      startTime: parsedStart.toUtc(),
      capacity: rawCapacity,
      reserved: rawReserved,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.title,
    required super.description,
    required super.price,
    required super.duration,
    required super.category,
    required super.image,
    required super.capacity,
    super.slots,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final rawSlots = map['slots'];
    final slots = <ServiceSlotEntity>[];
    if (rawSlots is List) {
      for (final raw in rawSlots) {
        if (raw is Map) {
          final slot = ServiceSlotModel.fromJson(
            Map<String, dynamic>.from(raw),
          );
          if (slot.id.isNotEmpty) slots.add(slot);
        }
      }
    }

    return ServiceModel(
      id: (map['_id'] ?? map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      price: _asDouble(map['price']) ?? 0,
      duration: _asInt(map['duration']) ?? 0,
      category: (map['category'] ?? '').toString(),
      image: (map['image'] ?? '').toString(),
      capacity:
          _asInt(map['capacityPerSlot']) ??
          _asInt(map['capacity']) ??
          _asInt(map['maxCapacity']) ??
          0,
      slots: slots,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'description': description,
    'price': price,
    'duration': duration,
    'category': category,
    'image': image,
    'capacityPerSlot': capacity,
    'slots': slots
        .map(
          (slot) => {
            '_id': slot.id,
            'startTime': slot.startTime.toIso8601String(),
            'capacity': slot.capacity,
            'reserved': slot.reserved,
          },
        )
        .toList(),
  };

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
