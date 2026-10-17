import 'dart:async';
import 'package:flutter/foundation.dart';
import 'bindable_property.dart';
import 'command.dart';
import 'mvvm_exception.dart';
import 'request_state.dart';

/// Base class for all ViewModels in the `flutter_mvvm_framework`.
///
/// A ViewModel acts as the pure presentation model for a View. It holds observable
/// state, properties, commands, and interacts with Repositories and Services.
///
/// It provides automatic lifecycle management, dependency disposal tracking,
/// and helper methods for executing asynchronous tasks cleanly.
abstract class MvvmViewModel extends ChangeNotifier {
  final List<Disposable> _disposables = [];
  final List<ChangeNotifier> _notifiers = [];
  final List<StreamSubscription> _subscriptions = [];

  bool _isDisposed = false;
  bool _isInitialized = false;

  /// Returns `true` if this ViewModel has been disposed.
  bool get isDisposed => _isDisposed;

  /// Returns `true` if [onInit] has been executed.
  bool get isInitialized => _isInitialized;

  /// Lifecycle method invoked once when the ViewModel is attached to its View.
  /// Subclasses should place asynchronous data loads or event listeners here.
  @mustCallSuper
  void onInit() {
    _isInitialized = true;
  }

  /// Lifecycle method called after the first frame has rendered.
  @mustCallSuper
  void onReady() {}

  /// Lifecycle method invoked when the ViewModel is being destroyed.
  /// Subclasses can override this to perform custom teardown before disposables are cleared.
  @mustCallSuper
  void onDispose() {}

  /// Creates and registers a new [Property] that will be automatically disposed
  /// when this ViewModel is destroyed.
  Property<T> createProperty<T>(T initialValue) {
    _assertNotDisposed();
    final prop = Property<T>(initialValue);
    _disposables.add(prop);
    return prop;
  }

  /// Creates and registers an [AsyncCommand] that will be automatically disposed
  /// when this ViewModel is destroyed.
  AsyncCommand<TParam, TResult> createAsyncCommand<TParam, TResult>({
    required Future<TResult> Function(TParam? param) action,
    bool Function(TParam? param)? canExecute,
  }) {
    _assertNotDisposed();
    final cmd = AsyncCommand<TParam, TResult>(
      action: action,
      canExecute: canExecute,
    );
    _disposables.add(cmd);
    return cmd;
  }

  /// Registers any [Disposable] object (like a [Property] or [MvvmCommand])
  /// to be cleaned up automatically on disposal.
  D registerDisposable<D extends Disposable>(D disposable) {
    _assertNotDisposed();
    _disposables.add(disposable);
    return disposable;
  }

  /// Registers a standard [ChangeNotifier] to be disposed when the ViewModel is destroyed.
  N registerNotifier<N extends ChangeNotifier>(N notifier) {
    _assertNotDisposed();
    _notifiers.add(notifier);
    return notifier;
  }

  /// Registers a [StreamSubscription] to be cancelled when the ViewModel is destroyed.
  StreamSubscription<T> registerSubscription<T>(StreamSubscription<T> subscription) {
    _assertNotDisposed();
    _subscriptions.add(subscription);
    return subscription;
  }

  /// Executes an asynchronous operation, automatically managing state transitions
  /// for a target [Property<RequestState<T>>].
  Future<T?> execute<T>({
    required Future<T> Function() action,
    required Property<RequestState<T>> stateProperty,
    void Function(T data)? onSuccess,
    void Function(dynamic error)? onError,
  }) async {
    _assertNotDisposed();

    final previousData = stateProperty.value.dataOrNull;
    stateProperty.value = RequestState<T>.loading(previousData: previousData);

    try {
      final result = await action();
      if (!_isDisposed) {
        stateProperty.value = RequestState<T>.success(result);
        onSuccess?.call(result);
      }
      return result;
    } catch (error, stackTrace) {
      if (!_isDisposed) {
        stateProperty.value = RequestState<T>.error(
          error,
          stackTrace: stackTrace,
          previousData: previousData,
        );
        onError?.call(error);
      }
      return null;
    }
  }

  void _assertNotDisposed() {
    if (_isDisposed) {
      throw const ViewModelDisposedException();
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      onDispose();

      for (final sub in _subscriptions) {
        unawaited(sub.cancel());
      }
      _subscriptions.clear();

      for (final d in _disposables) {
        d.dispose();
      }
      _disposables.clear();

      for (final n in _notifiers) {
        n.dispose();
      }
      _notifiers.clear();

      super.dispose();
    }
  }
}
