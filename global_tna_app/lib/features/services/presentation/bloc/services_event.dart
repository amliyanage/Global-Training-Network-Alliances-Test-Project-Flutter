import 'package:equatable/equatable.dart';

abstract class ServicesEvent extends Equatable {
  const ServicesEvent();

  @override
  List<Object?> get props => [];
}

class FetchServicesEvent extends ServicesEvent {
  final int page;
  final int limit;
  final String? category;
  final String? title;

  const FetchServicesEvent({
    this.page = 1,
    this.limit = 10,
    this.category,
    this.title,
  });

  @override
  List<Object?> get props => [page, limit, category, title];
}

class FetchServiceDetailEvent extends ServicesEvent {
  final String id;

  const FetchServiceDetailEvent(this.id);

  @override
  List<Object?> get props => [id];
}
