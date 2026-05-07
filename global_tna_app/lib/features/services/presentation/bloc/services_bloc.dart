import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/service_repository.dart';
import 'services_event.dart';
import 'services_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final ServiceRepository repository;
  bool _isFetchingMore = false;
  int _latestFetchRequestId = 0;
  String _activeQueryKey = '';

  ServicesBloc({required this.repository}) : super(ServicesInitial()) {
    on<FetchServicesEvent>(_onFetchServices);
    on<FetchServiceDetailEvent>(_onFetchServiceDetail);
  }

  Future<void> _onFetchServices(
    FetchServicesEvent event,
    Emitter<ServicesState> emit,
  ) async {
    final queryKey = _buildQueryKey(event);
    final isFirstPageRequest = event.page <= 1;

    if (isFirstPageRequest) {
      _activeQueryKey = queryKey;
    } else if (queryKey != _activeQueryKey) {
      return;
    }

    final currentState = state;
    final loadedState = currentState is ServicesLoaded ? currentState : null;
    final isLoadMore =
        loadedState != null && event.page > loadedState.currentPage;
    final requestId = ++_latestFetchRequestId;

    if (isLoadMore) {
      if (loadedState.hasReachedMax || _isFetchingMore) return;
      _isFetchingMore = true;
      emit(loadedState.copyWith(isLoadingMore: true));
    } else {
      emit(ServicesLoading());
    }

    try {
      final result = await repository.getServices(
        page: event.page,
        limit: event.limit,
        category: event.category,
        title: event.title,
      );

      if (_isStaleRequest(requestId, queryKey)) return;

      result.fold(
        (failure) {
          if (isLoadMore) {
            emit(loadedState.copyWith(isLoadingMore: false));
            return;
          }
          emit(ServicesError(failure.message));
        },
        (services) {
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
        },
      );
    } finally {
      if (isLoadMore) {
        _isFetchingMore = false;
      }
    }
  }

  bool _isStaleRequest(int requestId, String queryKey) {
    return requestId != _latestFetchRequestId || queryKey != _activeQueryKey;
  }

  String _buildQueryKey(FetchServicesEvent event) {
    return '${event.limit}|${event.category ?? ''}|${event.title ?? ''}';
  }

  Future<void> _onFetchServiceDetail(
    FetchServiceDetailEvent event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());
    final result = await repository.getServiceById(
      event.id,
      bookingDate: event.bookingDate,
    );

    result.fold(
      (failure) => emit(ServicesError(failure.message)),
      (service) => emit(ServiceDetailLoaded(service)),
    );
  }
}
