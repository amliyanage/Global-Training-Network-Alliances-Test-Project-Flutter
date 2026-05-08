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
  final bool isLoadingMore;
  final int currentPage;

  const ServicesLoaded(
    this.services, {
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.currentPage = 1,
  });

  ServicesLoaded copyWith({
    List<ServiceEntity>? services,
    bool? hasReachedMax,
    bool? isLoadingMore,
    int? currentPage,
  }) {
    return ServicesLoaded(
      services ?? this.services,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object> get props => [
    services,
    hasReachedMax,
    isLoadingMore,
    currentPage,
  ];
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
