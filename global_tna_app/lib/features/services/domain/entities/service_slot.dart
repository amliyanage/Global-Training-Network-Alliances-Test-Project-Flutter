import 'package:equatable/equatable.dart';

class ServiceSlotEntity extends Equatable {
  final String id;
  final DateTime startTime;
  final int capacity;
  final int reserved;

  const ServiceSlotEntity({
    required this.id,
    required this.startTime,
    required this.capacity,
    this.reserved = 0,
  });

  int get available => (capacity - reserved).clamp(0, capacity);
  bool get isFull => available <= 0;

  @override
  List<Object?> get props => [id, startTime, capacity, reserved];
}
