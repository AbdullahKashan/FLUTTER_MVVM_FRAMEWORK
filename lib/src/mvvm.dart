import 'package:http/http.dart' as http;
import 'auth/auth_interceptor.dart';
import 'auth/auth_manager.dart';
import 'dependency/service_locator.dart';
import 'network/api_client.dart';
import 'network/api_config.dart';
import 'network/interceptor.dart';
import 'storage/storage.dart';

/// Central entry point and configuration coordinator for `flutter_mvvm_framework`.
class MVVM {
  MVVM._();

  static final ServiceLocator _locator = ServiceLocator();

  /// Access to the global dependency injection service locator.
  static ServiceLocator get locator => _locator;

  /// Global REST [ApiClient] instance.
  static ApiClient get apiClient => _locator.get<ApiClient>();

  /// Global [AuthManager] instance.
  static AuthManager get authManager => _locator.get<AuthManager>();

  /// Global [Storage] instance.
  static Storage get storage => _locator.get<Storage>();

  /// Initializes the framework with core network, auth, and storage services.
  static Future<void> initialize({
    required String baseUrl,
    Storage? storage,
    http.Client? httpClient,
    Map<String, String>? defaultHeaders,
    Duration timeout = const Duration(seconds: 30),
    List<Interceptor> interceptors = const [],
    bool logging = false,
    Future<String> Function(String refreshToken)? onRefreshToken,
  }) async {
    // Register Storage
    final activeStorage = storage ?? MemoryStorage();
    if (!_locator.isRegistered<Storage>()) {
      _locator.registerSingleton<Storage>(activeStorage);
    }

    // Register AuthManager
    final authManager = AuthManager(
      storage: activeStorage,
      refreshHandler: onRefreshToken,
    );
    await authManager.initialize();
    if (!_locator.isRegistered<AuthManager>()) {
      _locator.registerSingleton<AuthManager>(authManager);
    }

    // Configure REST Client
    final allInterceptors = <Interceptor>[
      AuthInterceptor(
        authManager: authManager,
        clientProvider: () => _locator.get<ApiClient>(),
      ),
      ...interceptors,
    ];

    final config = ApiConfig(
      baseUrl: baseUrl,
      defaultHeaders: defaultHeaders ??
          const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
      timeout: timeout,
      interceptors: allInterceptors,
      loggingEnabled: logging,
    );

    final client = ApiClient(
      config: config,
      httpClient: httpClient,
    );

    if (!_locator.isRegistered<ApiClient>()) {
      _locator.registerSingleton<ApiClient>(client);
    }
  }

  /// Resets the framework services and clears dependencies in the locator.
  static void reset() {
    _locator.reset();
  }
}
