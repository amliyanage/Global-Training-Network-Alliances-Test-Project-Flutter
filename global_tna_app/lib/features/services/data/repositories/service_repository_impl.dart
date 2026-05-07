import 'package:dartz/dartz.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/exceptions/failures.dart';
import '../../domain/entities/service.dart';
import '../../domain/repositories/service_repository.dart';
import '../datasources/service_remote_data_source.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource remoteDataSource;

  ServiceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices({
    int page = 1,
    int limit = 10,
    String? category,
    String? title,
  }) async {
    try {
      final services = await remoteDataSource.getServices(
        page: page,
        limit: limit,
        category: category,
        title: title,
      );
      return Right(services);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on TypeError {
      return const Left(ServerFailure('Invalid services data format from API'));
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }

  @override
  Future<Either<Failure, ServiceEntity>> getServiceById(String id, {String? bookingDate}) async {
    try {
      final service = await remoteDataSource.getServiceById(id, bookingDate: bookingDate);
      return Right(service);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on TypeError {
      return const Left(ServerFailure('Invalid service data format from API'));
    } catch (e) {
      return const Left(ServerFailure("Unexpected error occurred"));
    }
  }
}
