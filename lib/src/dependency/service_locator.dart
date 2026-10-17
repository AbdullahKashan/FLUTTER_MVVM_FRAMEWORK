import '../core/mvvm_exception.dart';

/// Lightweight dependency injection service locator for managing singletons and factories.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  /// Global singleton instance.
  factory ServiceLocator() => _instance;

  ServiceLocator._internal();

  final Map<Type, dynamic> _singletons = {};
  final Map<Type, dynamic Function()> _factories = {};
  final Map<Type, dynamic Function()> _lazySingletons = {};

  /// Registers an existing instance as a singleton for type [T].
  void registerSingleton<T>(T instance) {
    if (isRegistered<T>()) {
      throw MvvmException('Type $T is already registered in ServiceLocator.');
    }
    _singletons[T] = instance;
  }

  /// Registers a factory that creates a new instance of [T] every time [get] is called.
  void registerFactory<T>(T Function() factory) {
    if (isRegistered<T>()) {
      throw MvvmException('Type $T is already registered in ServiceLocator.');
    }
    _factories[T] = factory;
  }

  /// Registers a lazy singleton that initializes the instance on its first retrieval.
  void registerLazySingleton<T>(T Function() factory) {
    if (isRegistered<T>()) {
      throw MvvmException('Type $T is already registered in ServiceLocator.');
    }
    _lazySingletons[T] = factory;
  }

  /// Resolves and returns the registered instance of type [T].
  T get<T>() {
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }

    if (_lazySingletons.containsKey(T)) {
      final instance = _lazySingletons[T]!() as T;
      _singletons[T] = instance;
      _lazySingletons.remove(T);
      return instance;
    }

    if (_factories.containsKey(T)) {
      return _factories[T]!() as T;
    }

    throw DependencyNotFoundException(T);
  }

  /// Checks if a dependency of type [T] has been registered.
  bool isRegistered<T>() {
    return _singletons.containsKey(T) ||
        _lazySingletons.containsKey(T) ||
        _factories.containsKey(T);
  }

  /// Clears all registered instances, singletons, and factories.
  void reset() {
    _singletons.clear();
    _factories.clear();
    _lazySingletons.clear();
  }
}
