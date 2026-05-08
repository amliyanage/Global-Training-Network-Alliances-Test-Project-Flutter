import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_tna_app/core/exceptions/failures.dart';
import 'package:global_tna_app/features/services/domain/entities/service.dart';
import 'package:global_tna_app/features/services/domain/repositories/service_repository.dart';
import 'package:global_tna_app/features/services/presentation/bloc/services_bloc.dart';
import 'package:global_tna_app/features/services/presentation/bloc/services_event.dart';
import 'package:global_tna_app/features/services/presentation/bloc/services_state.dart';

class _FakeServiceRepository implements ServiceRepository {
  Future<Either<Failure, List<ServiceEntity>>> Function({
    int page,
    int limit,
    String? category,
    String? title,
  })
  onGetServices =
      ({int page = 1, int limit = 10, String? category, String? title}) async {
        return const Right([]);
      };

  @override
  Future<Either<Failure, ServiceEntity>> getServiceById(
    String id, {
    String? bookingDate,
  }) async {
    return Left(ServerFailure('Not implemented'));
  }

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices({
    int page = 1,
    int limit = 10,
    String? category,
    String? title,
  }) {
    return onGetServices(
      page: page,
      limit: limit,
      category: category,
      title: title,
    );
  }
}

ServiceEntity _service(String id, String title) {
  return ServiceEntity(
    id: id,
    title: title,
    description: 'desc',
    price: 100,
    duration: 45,
    category: 'Cleaning',
    image: '',
    capacity: 3,
  );
}

void main() {
  group('ServicesBloc', () {
    late _FakeServiceRepository repo;
    late ServicesBloc bloc;

    setUp(() {
      repo = _FakeServiceRepository();
      bloc = ServicesBloc(repository: repo);
    });

    tearDown(() async {
      await bloc.close();
    });

    test('loads first page', () async {
      repo.onGetServices =
          ({
            int page = 1,
            int limit = 10,
            String? category,
            String? title,
          }) async {
            return Right([_service('1', 'Home Cleaning')]);
          };

      bloc.add(const FetchServicesEvent(page: 1, limit: 10));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ServicesLoading>(),
          predicate<ServicesState>((state) {
            return state is ServicesLoaded && state.services.length == 1;
          }),
        ]),
      );
    });

    test('appends on load-more', () async {
      repo.onGetServices =
          ({
            int page = 1,
            int limit = 10,
            String? category,
            String? title,
          }) async {
            if (page == 1) return Right([_service('1', 'Home Cleaning')]);
            return Right([_service('2', 'Office Cleaning')]);
          };

      final emitted = <ServicesState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(const FetchServicesEvent(page: 1, limit: 1));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const FetchServicesEvent(page: 2, limit: 1));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final hasMergedState = emitted.any((state) {
        return state is ServicesLoaded &&
            state.currentPage == 2 &&
            state.services.length == 2;
      });

      await sub.cancel();
      expect(hasMergedState, isTrue);
    });

    test('ignores stale responses when filters change quickly', () async {
      final oldFilterCompleter =
          Completer<Either<Failure, List<ServiceEntity>>>();
      final newFilterCompleter =
          Completer<Either<Failure, List<ServiceEntity>>>();

      repo.onGetServices =
          ({int page = 1, int limit = 10, String? category, String? title}) {
            if (title == 'old') return oldFilterCompleter.future;
            if (title == 'new') return newFilterCompleter.future;
            return Future.value(const Right([]));
          };

      bloc.add(const FetchServicesEvent(page: 1, limit: 10, title: 'old'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const FetchServicesEvent(page: 1, limit: 10, title: 'new'));

      newFilterCompleter.complete(Right([_service('2', 'Newest Service')]));
      await Future<void>.delayed(const Duration(milliseconds: 15));
      oldFilterCompleter.complete(Right([_service('1', 'Old Service')]));
      await Future<void>.delayed(const Duration(milliseconds: 25));

      expect(bloc.state, isA<ServicesLoaded>());
      final loaded = bloc.state as ServicesLoaded;
      expect(loaded.services.length, 1);
      expect(loaded.services.first.id, '2');
      expect(loaded.services.first.title, 'Newest Service');
    });

    test('keeps current list visible when load-more fails', () async {
      repo.onGetServices =
          ({
            int page = 1,
            int limit = 10,
            String? category,
            String? title,
          }) async {
            if (page == 1) return Right([_service('1', 'Home Cleaning')]);
            return Left(ServerFailure('Failed to load next page'));
          };

      final emitted = <ServicesState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(const FetchServicesEvent(page: 1, limit: 1));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const FetchServicesEvent(page: 2, limit: 1));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final hasErrorState = emitted.any((state) => state is ServicesError);
      final endedWithLoadedState = bloc.state is ServicesLoaded;
      final loaded = bloc.state as ServicesLoaded;

      await sub.cancel();

      expect(hasErrorState, isFalse);
      expect(endedWithLoadedState, isTrue);
      expect(loaded.services.length, 1);
      expect(loaded.isLoadingMore, isFalse);
      expect(loaded.currentPage, 1);
    });
  });
}
