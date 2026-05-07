import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/service_repository.dart';
import 'services_event.dart';
import 'services_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final ServiceRepository repository;
  bool _isFetchingMore = false;

  ServicesBloc({required this.repository}) : super(ServicesInitial()) {
    on<FetchServicesEvent>(_onFetchServices);
    on<FetchServiceDetailEvent>(_onFetchServiceDetail);
  }

  Future<void> _onFetchServices(
    FetchServicesEvent event,
    Emitter<ServicesState> emit,
  ) async {
    final currentState = state;
    final loadedState = currentState is ServicesLoaded ? currentState : null;
    final isLoadMore =
        loadedState != null && event.page > loadedState.currentPage;

    if (isLoadMore) {
      if (loadedState.hasReachedMax || _isFetchingMore) return;
      _isFetchingMore = true;
      emit(loadedState.copyWith(isLoadingMore: true));
    } else {
      emit(ServicesLoading());
    }

    final result = await repository.getServices(
      page: event.page,
      limit: event.limit,
      category: event.category,
      title: event.title,
    );

    result.fold((failure) => emit(ServicesError(failure.message)), (services) {
      if (isLoadMore) {
        final mergedServices = [...loadedState.services, ...services];
        emit(
          ServicesLoaded(
            mergedServices,
            hasReachedMax: services.length < event.limit,
            isLoadingMore: false,
            currentPage: event.page,
          ),
        );
        return;
      }

      emit(
        ServicesLoaded(
          services,
          hasReachedMax: services.length < event.limit,
          currentPage: event.page,
        ),
      );
    });

    if (isLoadMore) {
      _isFetchingMore = false;
    }
  }

  Future<void> _onFetchServiceDetail(
    FetchServiceDetailEvent event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());
    final result = await repository.getServiceById(event.id);

    result.fold(
      (failure) => emit(ServicesError(failure.message)),
      (service) => emit(ServiceDetailLoaded(service)),
    );
  }
}
