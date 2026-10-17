import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'http_method.dart';
import 'interceptor.dart';
import 'multipart_request.dart';

/// Core HTTP client for executing REST requests within the `flutter_mvvm_framework`.
class ApiClient {
  /// Configuration options for the client.
  ApiConfig config;

  final http.Client _httpClient;
  final List<Interceptor> _interceptors = [];

  ApiClient({
    required this.config,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client() {
    _interceptors.addAll(config.interceptors);
    if (config.loggingEnabled) {
      _interceptors.add(const LoggingInterceptor());
    }
  }

  /// Adds an interceptor to the execution pipeline.
  void addInterceptor(Interceptor interceptor) {
    _interceptors.add(interceptor);
  }

  /// Removes an interceptor from the execution pipeline.
  void removeInterceptor(Interceptor interceptor) {
    _interceptors.remove(interceptor);
  }

  /// Executes an HTTP GET request.
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(dynamic json)? parser,
  }) {
    return _sendRequest<T>(
      method: HttpMethod.get,
      path: path,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
      parser: parser,
    );
  }

  /// Executes an HTTP POST request.
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(dynamic json)? parser,
  }) {
    return _sendRequest<T>(
      method: HttpMethod.post,
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
      parser: parser,
    );
  }

  /// Executes an HTTP PUT request.
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(dynamic json)? parser,
  }) {
    return _sendRequest<T>(
      method: HttpMethod.put,
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
      parser: parser,
    );
  }

  /// Executes an HTTP PATCH request.
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(dynamic json)? parser,
  }) {
    return _sendRequest<T>(
      method: HttpMethod.patch,
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
      parser: parser,
    );
  }

  /// Executes an HTTP DELETE request.
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(dynamic json)? parser,
  }) {
    return _sendRequest<T>(
      method: HttpMethod.delete,
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
      parser: parser,
    );
  }

  /// Executes an HTTP multipart request for file uploads.
  Future<ApiResponse<T>> upload<T>(
    String path, {
    required List<MultipartFile> files,
    Map<String, String>? fields,
    HttpMethod method = HttpMethod.post,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(dynamic json)? parser,
  }) async {
    final uri = _buildUri(path, queryParameters);
    var options = RequestOptions(
      uri: uri,
      method: method,
      headers: {...config.defaultHeaders, ...?headers},
      timeout: timeout ?? config.timeout,
    );

    for (final interceptor in _interceptors) {
      options = await interceptor.onRequest(options);
    }

    final request = http.MultipartRequest(options.method.name.toUpperCase(), options.uri);
    request.headers.addAll(options.headers);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          file.field,
          file.bytes,
          filename: file.filename,
          contentType: file.contentType,
        ),
      );
    }

    try {
      final streamedResponse = await _httpClient.send(request).timeout(options.timeout!);
      final response = await http.Response.fromStream(streamedResponse);
      return await _processResponse<T>(response, parser: parser);
    } on TimeoutException {
      throw const TimeoutException('Upload request timed out');
    } on SocketException catch (e, stack) {
      throw NetworkException('Network error during upload', cause: e, stackTrace: stack);
    } catch (e, stack) {
      if (e is ApiException) rethrow;
      throw NetworkException('Unexpected upload error: $e', cause: e, stackTrace: stack);
    }
  }

  Future<ApiResponse<T>> _sendRequest<T>({
    required HttpMethod method,
    required String path,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(dynamic json)? parser,
  }) async {
    final uri = _buildUri(path, queryParameters);
    var options = RequestOptions(
      uri: uri,
      method: method,
      headers: {...config.defaultHeaders, ...?headers},
      body: body,
      timeout: timeout ?? config.timeout,
    );

    for (final interceptor in _interceptors) {
      options = await interceptor.onRequest(options);
    }

    http.Response rawResponse;
    try {
      final requestTimeout = options.timeout ?? config.timeout;
      switch (options.method) {
        case HttpMethod.get:
          rawResponse = await _httpClient
              .get(options.uri, headers: options.headers)
              .timeout(requestTimeout);
        case HttpMethod.post:
          rawResponse = await _httpClient
              .post(options.uri, headers: options.headers, body: _encodeBody(options.body))
              .timeout(requestTimeout);
        case HttpMethod.put:
          rawResponse = await _httpClient
              .put(options.uri, headers: options.headers, body: _encodeBody(options.body))
              .timeout(requestTimeout);
        case HttpMethod.patch:
          rawResponse = await _httpClient
              .patch(options.uri, headers: options.headers, body: _encodeBody(options.body))
              .timeout(requestTimeout);
        case HttpMethod.delete:
          rawResponse = await _httpClient
              .delete(options.uri, headers: options.headers, body: _encodeBody(options.body))
              .timeout(requestTimeout);
        case HttpMethod.head:
          rawResponse = await _httpClient
              .head(options.uri, headers: options.headers)
              .timeout(requestTimeout);
      }
    } on TimeoutException {
      const error = TimeoutException('Request timed out');
      return _handleException<T>(error);
    } on SocketException catch (e, stack) {
      final error = NetworkException('No internet connection or host unreachable', cause: e, stackTrace: stack);
      return _handleException<T>(error);
    } catch (e, stack) {
      if (e is ApiException) {
        return _handleException<T>(e);
      }
      final error = NetworkException('Network request failed: $e', cause: e, stackTrace: stack);
      return _handleException<T>(error);
    }

    return _processResponse<T>(rawResponse, parser: parser);
  }

  Uri _buildUri(String path, Map<String, dynamic>? queryParams) {
    var base = config.baseUrl;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }

    var cleanPath = path;
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }

    final fullUrl = '$base$cleanPath';
    final parsedUri = Uri.parse(fullUrl);

    if (queryParams != null && queryParams.isNotEmpty) {
      final mergedParams = Map<String, dynamic>.from(parsedUri.queryParameters);
      queryParams.forEach((key, value) {
        if (value != null) {
          mergedParams[key] = value.toString();
        }
      });
      return parsedUri.replace(queryParameters: mergedParams);
    }

    return parsedUri;
  }

  dynamic _encodeBody(dynamic body) {
    if (body == null) return null;
    if (body is String) return body;
    if (body is Map || body is List) {
      return jsonEncode(body);
    }
    return body.toString();
  }

  Future<ApiResponse<T>> _processResponse<T>(
    http.Response rawResponse, {
    T Function(dynamic json)? parser,
  }) async {
    final statusCode = rawResponse.statusCode;
    final rawBody = rawResponse.body;
    final headers = rawResponse.headers;

    if (statusCode < 200 || statusCode >= 300) {
      final error = _mapStatusCodeToException(statusCode, rawBody);
      for (final interceptor in _interceptors) {
        final result = await interceptor.onError(error);
        if (result is ApiResponse<T>) {
          return result;
        }
      }
      throw error;
    }

    dynamic decodedData;
    if (rawBody.isNotEmpty) {
      try {
        decodedData = jsonDecode(rawBody);
      } catch (_) {
        decodedData = rawBody;
      }
    }

    T parsedData;
    if (parser != null) {
      parsedData = parser(decodedData);
    } else if (decodedData is T) {
      parsedData = decodedData;
    } else {
      parsedData = decodedData as T;
    }

    var apiResponse = ApiResponse<T>(
      statusCode: statusCode,
      data: parsedData,
      headers: headers,
      rawBody: rawBody,
    );

    for (final interceptor in _interceptors) {
      apiResponse = (await interceptor.onResponse(apiResponse)) as ApiResponse<T>;
    }

    return apiResponse;
  }

  Future<ApiResponse<T>> _handleException<T>(ApiException error) async {
    for (final interceptor in _interceptors) {
      final result = await interceptor.onError(error);
      if (result is ApiResponse<T>) {
        return result;
      }
    }
    throw error;
  }

  ApiException _mapStatusCodeToException(int statusCode, String body) {
    dynamic decoded;
    String message = 'HTTP request failed with status code $statusCode';

    try {
      decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
      }
    } catch (_) {}

    switch (statusCode) {
      case 400:
        return BadRequestException(message, responseBody: body);
      case 401:
        return UnauthorizedException(message, responseBody: body);
      case 403:
        return ForbiddenException(message, responseBody: body);
      case 404:
        return NotFoundException(message, responseBody: body);
      case 422:
        Map<String, List<String>> errors = {};
        if (decoded is Map && decoded['errors'] is Map) {
          (decoded['errors'] as Map).forEach((k, v) {
            if (v is List) {
              errors[k.toString()] = v.map((e) => e.toString()).toList();
            } else if (v is String) {
              errors[k.toString()] = [v];
            }
          });
        }
        return ValidationException(message, responseBody: body, errors: errors);
      default:
        if (statusCode >= 500) {
          return ServerException(message, statusCode: statusCode, responseBody: body);
        }
        return BadRequestException(message, statusCode: statusCode, responseBody: body);
    }
  }

  /// Closes the client and frees resources.
  void dispose() {
    _httpClient.close();
  }
}
