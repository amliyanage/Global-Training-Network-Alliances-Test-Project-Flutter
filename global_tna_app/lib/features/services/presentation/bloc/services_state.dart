import 'package:equatable/equatable.dart';
import '../../domain/entities/service.dart';

abstract class ServicesState extends Equatable {
  const ServicesState();
  
  @override
  List<Object> get props => [];
}

class ServicesInitial extends ServicesState {}

class ServicesLoading extends ServicesState {}

class ServicesLoaded extends ServicesState {
  final List<ServiceEntity> services;
  final bool hasReachedMax;

  const ServicesLoaded(this.services, {this.hasReachedMax = false});

  @override
  List<Object> get props => [services, hasReachedMax];
}

class ServiceDetailLoaded extends ServicesState {
  final ServiceEntity service;

  const ServiceDetailLoaded(this.service);

  @override
  List<Object> get props => [service];
}

class ServicesError extends ServicesState {
  final String message;

  const ServicesError(this.message);

  @override
  List<Object> get props => [message];
}
