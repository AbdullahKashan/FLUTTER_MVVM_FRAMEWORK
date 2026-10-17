import 'interceptor.dart';

/// Configuration options for the REST [ApiClient].
class ApiConfig {
  /// Base URL prepended to all request paths.
  final String baseUrl;

  /// Default headers attached to every outgoing request.
  final Map<String, String> defaultHeaders;

  /// Global request timeout duration.
  final Duration timeout;

  /// List of interceptors executed in order on each request.
  final List<Interceptor> interceptors;

  /// Whether HTTP logging is enabled.
  final bool loggingEnabled;

  ApiConfig({
    required this.baseUrl,
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    this.timeout = const Duration(seconds: 30),
    this.interceptors = const [],
    this.loggingEnabled = false,
  });

  /// Creates a copy of this configuration with updated fields.
  ApiConfig copyWith({
    String? baseUrl,
    Map<String, String>? defaultHeaders,
    Duration? timeout,
    List<Interceptor>? interceptors,
    bool? loggingEnabled,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      timeout: timeout ?? this.timeout,
      interceptors: interceptors ?? this.interceptors,
      loggingEnabled: loggingEnabled ?? this.loggingEnabled,
    );
  }
}
