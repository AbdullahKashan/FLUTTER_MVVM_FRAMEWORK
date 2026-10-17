## 1.0.0

- Initial release of `flutter_mvvm_framework`.
- True Model-View-ViewModel (MVVM) architecture with decoupled Presentation Models.
- Reactive `Property<T>` and `ReadOnlyProperty<T>` for surgical, granular UI rebuilds without rebuilding entire screens.
- `MvvmCommand<TParam, TResult>` and `AsyncCommand<TParam, TResult>` with automatic `canExecute` disabling and loading states.
- `MvvmViewModel` base class with managed lifecycle (`onInit`, `onReady`, `onDispose`), auto-disposable registration, and asynchronous `execute()` helper.
- `ViewModelProvider<VM>` InheritedWidget and `MvvmView<VM>` widget layer for automatic ViewModel lifecycle attachment.
- `Bind<T>` (alias `PropertyBuilder<T>`), `CommandButton`, and `MvvmBuilder<VM>` widgets.
- Complete industrial-grade REST `ApiClient` supporting GET, POST, PUT, PATCH, DELETE, and Multipart uploads.
- Auto-refreshing JWT authentication with concurrency mutex queue to prevent race conditions on HTTP 401.
- `BaseRepository<T>` and `MvvmModel` abstractions for type-safe data access and JSON mapping.
- `PaginationViewModel<T>` with built-in infinite scrolling, refresh commands, and page bounds.
- Built-in lightweight `ServiceLocator` and pluggable `Storage` system.
- Comprehensive test suite and ready-to-run example application.
