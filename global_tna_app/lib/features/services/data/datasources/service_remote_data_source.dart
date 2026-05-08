import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_error_mapper.dart';
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
      if (kDebugMode) {
        debugPrint('GET /services query: $queryParams');
      }

      final response = await dioClient.dio.get(
        '/services',
        queryParameters: queryParams,
      );
      final root = _asMap(response.data);
      final nested = _asMap(root['data']);
      final List<dynamic> data =
          (nested['data'] as List?) ??
          (root['data'] as List?) ??
          (root['services'] as List?) ??
          const [];
      final parsed = data
          .whereType<Map>()
          .map((json) => ServiceModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      if (kDebugMode) {
        debugPrint('GET /services -> ${parsed.length} items');
      }
      return parsed;
    } on DioException catch (e) {
      throw ApiErrorMapper.mapDioException(
        e,
        fallbackMessage: 'Failed to load services',
      );
    }
  }

  @override
  Future<ServiceModel> getServiceById(String id, {String? bookingDate}) async {
    try {
      final response = await dioClient.dio.get(
        '/services/$id',
        queryParameters: {'bookingDate': bookingDate}
          ..removeWhere((key, value) => value == null),
      );
      final root = _asMap(response.data);
      final data = _asMap(root['data']);
      final payload = data.isNotEmpty ? data : root;
      return ServiceModel.fromJson(payload);
    } on DioException catch (e) {
      throw ApiErrorMapper.mapDioException(
        e,
        fallbackMessage: 'Failed to load service',
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}
