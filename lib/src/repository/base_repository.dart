import '../core/mvvm_model.dart';
import '../network/api_client.dart';
import '../network/api_response.dart';

/// Base repository providing standardized CRUD operations and API interactions
/// for models of type [T].
abstract class BaseRepository<T extends MvvmModel> {
  /// The API client used to perform HTTP operations.
  final ApiClient apiClient;

  /// The base endpoint path for this repository (e.g., `'/users'`).
  final String endpoint;

  /// Function to parse a JSON map into a model instance of type [T].
  final T Function(Map<String, dynamic> json) fromJson;

  const BaseRepository({
    required this.apiClient,
    required this.endpoint,
    required this.fromJson,
  });

  /// Fetches a list of models from [endpoint].
  Future<List<T>> getAll({
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await apiClient.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      headers: headers,
    );

    final data = response.data;
    if (data is List) {
      return data
          .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } else if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  /// Fetches a single model by its [id].
  Future<T> getById(
    dynamic id, {
    Map<String, String>? headers,
  }) async {
    final response = await apiClient.get<dynamic>(
      '$endpoint/$id',
      headers: headers,
    );

    final data = response.data;
    if (data is Map) {
      final itemMap = (data['data'] is Map) ? data['data'] as Map : data;
      return fromJson(Map<String, dynamic>.from(itemMap));
    }
    throw FormatException('Unexpected response format when fetching $endpoint/$id');
  }

  /// Creates a new model instance on the server.
  Future<T> create(
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final response = await apiClient.post<dynamic>(
      endpoint,
      body: body,
      headers: headers,
    );

    final data = response.data;
    if (data is Map) {
      final itemMap = (data['data'] is Map) ? data['data'] as Map : data;
      return fromJson(Map<String, dynamic>.from(itemMap));
    }
    throw FormatException('Unexpected response format when creating on $endpoint');
  }

  /// Updates an existing model instance on the server.
  Future<T> update(
    dynamic id,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final response = await apiClient.put<dynamic>(
      '$endpoint/$id',
      body: body,
      headers: headers,
    );

    final data = response.data;
    if (data is Map) {
      final itemMap = (data['data'] is Map) ? data['data'] as Map : data;
      return fromJson(Map<String, dynamic>.from(itemMap));
    }
    throw FormatException('Unexpected response format when updating $endpoint/$id');
  }

  /// Deletes a model instance by [id].
  Future<ApiResponse<dynamic>> delete(
    dynamic id, {
    Map<String, String>? headers,
  }) async {
    return apiClient.delete(
      '$endpoint/$id',
      headers: headers,
    );
  }
}

/// Generic repository for ad-hoc or simple model endpoints.
class MvvmRepository<T extends MvvmModel> extends BaseRepository<T> {
  const MvvmRepository({
    required super.apiClient,
    required super.endpoint,
    required super.fromJson,
  });
}
