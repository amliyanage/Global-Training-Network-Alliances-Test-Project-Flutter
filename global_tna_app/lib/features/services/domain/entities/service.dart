import 'package:equatable/equatable.dart';

class ServiceEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final int duration; // e.g. in minutes
  final String category;
  final String image;
  final int capacity;

  const ServiceEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.category,
    required this.image,
    required this.capacity,
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
      ];
}
