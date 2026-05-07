import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/service.dart';

part 'service_model.g.dart';

@JsonSerializable()
class ServiceModel extends ServiceEntity {
  const ServiceModel({
    @JsonKey(name: '_id') required super.id,
    required super.title,
    required super.description,
    required super.price,
    required super.duration,
    required super.category,
    required super.image,
    @JsonKey(name: 'capacityPerSlot') required super.capacity,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceModelFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceModelToJson(this);
}
