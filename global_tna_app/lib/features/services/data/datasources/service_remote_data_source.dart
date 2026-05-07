import 'package:dio/dio.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../models/service_model.dart';
import '../../../../core/network/dio_client.dart';

abstract class ServiceRemoteDataSource {
  Future<List<ServiceModel>> getServices({
    int page = 1,
    int limit = 10,
    String? category,
    String? title,
  });
  
  Future<ServiceModel> getServiceById(String id, {String? bookingDate});
}

class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  final DioClient dioClient;

  ServiceRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ServiceModel>> getServices({
    int page = 1,
    int limit = 10,
    String? category,
    String? title,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (category != null && category.isNotEmpty) 'category': category,
        if (title != null && title.isNotEmpty) 'title': title,
      };

      final response = await dioClient.dio.get('/services', queryParameters: queryParams);
      // Assuming response structure: { "data": [...], "total": ..., "hasMore": ... }
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => ServiceModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data['message'] ?? 'Failed to load services');
    }
  }

  @override
  Future<ServiceModel> getServiceById(String id, {String? bookingDate}) async {
    try {
      final response = await dioClient.dio.get(
        '/services/$id',
        queryParameters: {
          'bookingDate': bookingDate,
        }..removeWhere((key, value) => value == null),
      );
      // Assuming response body: { "data": {...} } or just {...}
      final data = response.data['data'] ?? response.data;
      return ServiceModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data['message'] ?? 'Failed to load service');
    }
  }
}
