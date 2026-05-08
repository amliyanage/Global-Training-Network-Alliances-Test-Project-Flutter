import 'package:equatable/equatable.dart';
import 'service_slot.dart';

class ServiceEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final int duration;
  final String category;
  final String image;
  final int capacity;
  final List<ServiceSlotEntity> slots;

  const ServiceEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.category,
    required this.image,
    required this.capacity,
    this.slots = const [],
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    price,
    duration,
    category,
    image,
    capacity,
    slots,
  ];
}
