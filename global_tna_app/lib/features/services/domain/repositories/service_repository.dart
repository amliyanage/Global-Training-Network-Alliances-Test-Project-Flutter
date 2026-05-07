import 'package:dartz/dartz.dart';
import '../../../../core/exceptions/failures.dart';
import '../entities/service.dart';

abstract class ServiceRepository {
  Future<Either<Failure, List<ServiceEntity>>> getServices({
    int page = 1,
    int limit = 10,
    String? category,
    String? title,
  });
  
  Future<Either<Failure, ServiceEntity>> getServiceById(String id, {String? bookingDate});
}
