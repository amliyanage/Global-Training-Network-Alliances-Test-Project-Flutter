import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/service_repository.dart';
import 'services_event.dart';
import 'services_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final ServiceRepository repository;

  ServicesBloc({required this.repository}) : super(ServicesInitial()) {
    on<FetchServicesEvent>(_onFetchServices);
    on<FetchServiceDetailEvent>(_onFetchServiceDetail);
  }

  Future<void> _onFetchServices(FetchServicesEvent event, Emitter<ServicesState> emit) async {
    emit(ServicesLoading());
    final result = await repository.getServices(
      page: event.page,
      limit: event.limit,
      category: event.category,
      title: event.title,
    );

    result.fold(
      (failure) => emit(ServicesError(failure.message)),
      (services) => emit(ServicesLoaded(services)),
    );
  }

  Future<void> _onFetchServiceDetail(FetchServiceDetailEvent event, Emitter<ServicesState> emit) async {
    emit(ServicesLoading());
    final result = await repository.getServiceById(event.id);

    result.fold(
      (failure) => emit(ServicesError(failure.message)),
      (service) => emit(ServiceDetailLoaded(service)),
    );
  }
}
