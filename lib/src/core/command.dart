import 'dart:async';
import 'package:flutter/foundation.dart';
import 'bindable_property.dart';
import 'mvvm_exception.dart';

/// An executable command in MVVM that encapsulates an action and its execution state.
///
/// Commands can be bound to UI elements (such as buttons). When [canExecute] is false
/// or the command is already running, execution is prevented and bound UI widgets
/// can automatically disable themselves.
abstract class MvvmCommand<TParam, TResult> extends ChangeNotifier implements Disposable {
  /// Whether the command is currently executing an asynchronous action.
  bool get isExecuting;

  /// Whether the command can currently be executed.
  bool get canExecute;

  /// The most recent result from executing the command.
  TResult? get lastResult;

  /// The most recent error encountered during execution.
  dynamic get lastError;

  /// Executes the command with the provided [param].
  Future<TResult?> execute([TParam? param]);

  /// Factory for creating a synchronous command.
  factory MvvmCommand.sync({
    required TResult Function(TParam? param) action,
    bool Function(TParam? param)? canExecute,
  }) = _SyncMvvmCommand<TParam, TResult>;

  /// Factory for creating an asynchronous command.
  factory MvvmCommand.async({
    required Future<TResult> Function(TParam? param) action,
    bool Function(TParam? param)? canExecute,
  }) = _AsyncMvvmCommand<TParam, TResult>;
}

/// Specialized asynchronous command exposing reactive properties for UI binding.
class AsyncCommand<TParam, TResult> extends ChangeNotifier implements MvvmCommand<TParam, TResult> {
  final Future<TResult> Function(TParam? param) action;
  final bool Function(TParam? param)? _canExecutePredicate;

  final Property<bool> _isExecutingProperty = Property<bool>(false);
  final Property<TResult?> _lastResultProperty = Property<TResult?>(null);
  final Property<dynamic> _lastErrorProperty = Property<dynamic>(null);

  bool _isDisposed = false;

  AsyncCommand({
    required this.action,
    bool Function(TParam? param)? canExecute,
  }) : _canExecutePredicate = canExecute;

  @override
  bool get isExecuting => _isExecutingProperty.value;

  /// Observable property tracking execution state.
  ReadOnlyProperty<bool> get isExecutingProperty => _isExecutingProperty.asReadOnly();

  @override
  bool get canExecute {
    if (_isDisposed) return false;
    if (isExecuting) return false;
    if (_canExecutePredicate != null) {
      return _canExecutePredicate(null);
    }
    return true;
  }

  /// Evaluates whether the command can execute with a specific parameter.
  bool canExecuteWith(TParam? param) {
    if (_isDisposed) return false;
    if (isExecuting) return false;
    if (_canExecutePredicate != null) {
      return _canExecutePredicate(param);
    }
    return true;
  }

  @override
  TResult? get lastResult => _lastResultProperty.value;

  @override
  dynamic get lastError => _lastErrorProperty.value;

  @override
  Future<TResult?> execute([TParam? param]) async {
    if (_isDisposed) {
      throw const ViewModelDisposedException('Cannot execute command on a disposed instance.');
    }

    if (!canExecuteWith(param)) {
      return null;
    }

    _isExecutingProperty.value = true;
    _lastErrorProperty.value = null;
    notifyListeners();

    try {
      final result = await action(param);
      if (!_isDisposed) {
        _lastResultProperty.value = result;
      }
      return result;
    } catch (e, stackTrace) {
      if (!_isDisposed) {
        _lastErrorProperty.value = e;
      }
      throw CommandExecutionException('Command execution failed', cause: e, stackTrace: stackTrace);
    } finally {
      if (!_isDisposed) {
        _isExecutingProperty.value = false;
        notifyListeners();
      }
    }
  }

  /// Notifies the command that external conditions have changed, re-evaluating [canExecute].
  void notifyCanExecuteChanged() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _isExecutingProperty.dispose();
      _lastResultProperty.dispose();
      _lastErrorProperty.dispose();
      super.dispose();
    }
  }
}

class _SyncMvvmCommand<TParam, TResult> extends ChangeNotifier implements MvvmCommand<TParam, TResult> {
  final TResult Function(TParam? param) action;
  final bool Function(TParam? param)? _canExecutePredicate;

  bool _isExecuting = false;
  TResult? _lastResult;
  dynamic _lastError;
  bool _isDisposed = false;

  _SyncMvvmCommand({
    required this.action,
    bool Function(TParam? param)? canExecute,
  }) : _canExecutePredicate = canExecute;

  @override
  bool get isExecuting => _isExecuting;

  @override
  bool get canExecute {
    if (_isDisposed) return false;
    if (_canExecutePredicate != null) {
      return _canExecutePredicate(null);
    }
    return true;
  }

  @override
  TResult? get lastResult => _lastResult;

  @override
  dynamic get lastError => _lastError;

  @override
  Future<TResult?> execute([TParam? param]) async {
    if (_isDisposed) {
      throw const ViewModelDisposedException('Cannot execute command on a disposed instance.');
    }

    if (!canExecute) return null;

    _isExecuting = true;
    _lastError = null;
    notifyListeners();

    try {
      final result = action(param);
      _lastResult = result;
      return result;
    } catch (e, stackTrace) {
      _lastError = e;
      throw CommandExecutionException('Command execution failed', cause: e, stackTrace: stackTrace);
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      super.dispose();
    }
  }
}

class _AsyncMvvmCommand<TParam, TResult> extends AsyncCommand<TParam, TResult> {
  _AsyncMvvmCommand({
    required super.action,
    super.canExecute,
  });
}
