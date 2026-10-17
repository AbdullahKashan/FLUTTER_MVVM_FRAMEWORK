/// A modular, robust, and batteries-included Model-View-ViewModel (MVVM) framework
/// for Flutter applications with reactive properties, commands, REST client,
/// automated JWT authentication, and pagination.
library;

// Core
export 'src/mvvm.dart';
export 'src/core/view_model.dart';
export 'src/core/bindable_property.dart';
export 'src/core/command.dart';
export 'src/core/request_state.dart';
export 'src/core/mvvm_model.dart';
export 'src/core/mvvm_exception.dart';

// View & Bindings
export 'src/view/mvvm_view.dart';
export 'src/view/view_model_provider.dart';
export 'src/view/property_builder.dart';
export 'src/view/command_builder.dart';
export 'src/view/mvvm_builder.dart';
export 'src/view/two_way_binding.dart';
export 'src/view/loading_view.dart';
export 'src/view/error_view.dart';

// Network
export 'src/network/api_client.dart';
export 'src/network/api_config.dart';
export 'src/network/api_response.dart';
export 'src/network/api_exception.dart';
export 'src/network/http_method.dart';
export 'src/network/interceptor.dart';
export 'src/network/multipart_request.dart';

// Auth
export 'src/auth/auth_manager.dart';
export 'src/auth/token_manager.dart';
export 'src/auth/auth_interceptor.dart';

// Repository
export 'src/repository/base_repository.dart';

// Storage
export 'src/storage/storage.dart';
export 'src/storage/secure_storage.dart';

// Pagination
export 'src/pagination/pagination_view_model.dart';

// Dependency Injection
export 'src/dependency/service_locator.dart';
