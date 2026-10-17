import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'http_method.dart';

/// Mutable options representing an HTTP request before execution.
class RequestOptions {
  Uri uri;
  HttpMethod method;
  Map<String, String> headers;
  dynamic body;
  Duration? timeout;

  RequestOptions({
    required this.uri,
    required this.method,
    Map<String, String>? headers,
    this.body,
    this.timeout,
  }) : headers = headers != null ? Map<String, String>.from(headers) : {};

  /// Creates a copy of this request options instance.
  RequestOptions copyWith({
    Uri? uri,
    HttpMethod? method,
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) {
    return RequestOptions(
      uri: uri ?? this.uri,
      method: method ?? this.method,
      headers: headers ?? Map<String, String>.from(this.headers),
      body: body ?? this.body,
      timeout: timeout ?? this.timeout,
    );
  }
}

/// Middleware contract for intercepting and mutating HTTP requests, responses, and errors.
abstract class Interceptor {
  const Interceptor();

  /// Invoked before an HTTP request is transmitted over the wire.
  FutureOr<RequestOptions> onRequest(RequestOptions options) => options;

  /// Invoked after receiving a successful HTTP response.
  FutureOr<ApiResponse<dynamic>> onResponse(ApiResponse<dynamic> response) => response;

  /// Invoked when a request encounters an error or non-2xx status code.
  FutureOr<dynamic> onError(ApiException error) => error;
}

/// Built-in interceptor that logs detailed HTTP request and response information.
class LoggingInterceptor extends Interceptor {
  const LoggingInterceptor();

  @override
  RequestOptions onRequest(RequestOptions options) {
    if (kDebugMode) {
      debugPrint('--> ${options.method.name.toUpperCase()} ${options.uri}');
      if (options.headers.isNotEmpty) {
        debugPrint('Headers: ${options.headers}');
      }
      if (options.body != null) {
        debugPrint('Body: ${options.body}');
      }
      debugPrint('--> END ${options.method.name.toUpperCase()}');
    }
    return options;
  }

  @override
  ApiResponse<dynamic> onResponse(ApiResponse<dynamic> response) {
    if (kDebugMode) {
      debugPrint('<-- ${response.statusCode} (${response.rawBody.length} bytes)');
      debugPrint('Data: ${response.data}');
      debugPrint('<-- END HTTP');
    }
    return response;
  }

  @override
  dynamic onError(ApiException error) {
    if (kDebugMode) {
      debugPrint('<-- ERROR ${error.statusCode ?? "NETWORK"}: ${error.message}');
      if (error.responseBody != null) {
        debugPrint('Response: ${error.responseBody}');
      }
      debugPrint('<-- END ERROR');
    }
    return error;
  }
}

/// Built-in interceptor that appends static or dynamic headers to all outgoing requests.
class HeadersInterceptor extends Interceptor {
  final Map<String, String> Function() headersProvider;

  HeadersInterceptor(this.headersProvider);

  factory HeadersInterceptor.fromMap(Map<String, String> headers) {
    return HeadersInterceptor(() => headers);
  }

  @override
  RequestOptions onRequest(RequestOptions options) {
    options.headers.addAll(headersProvider());
    return options;
  }
}
