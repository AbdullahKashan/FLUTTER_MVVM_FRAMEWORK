import 'package:flutter/foundation.dart';

/// Represents the discrete states of an asynchronous operation in MVVM.
@immutable
sealed class RequestState<T> {
  const RequestState();

  /// Creates an idle state before any action is performed.
  const factory RequestState.idle() = IdleState<T>;

  /// Creates a loading state indicating an action is in progress.
  const factory RequestState.loading({T? previousData}) = LoadingState<T>;

  /// Creates a success state containing the resolved [data].
  const factory RequestState.success(T data) = SuccessState<T>;

  /// Creates an error state containing the [error] and optional [stackTrace].
  const factory RequestState.error(dynamic error, {StackTrace? stackTrace, T? previousData}) =
      ErrorState<T>;

  /// Returns `true` if this state is [IdleState].
  bool get isIdle => this is IdleState<T>;

  /// Returns `true` if this state is [LoadingState].
  bool get isLoading => this is LoadingState<T>;

  /// Returns `true` if this state is [SuccessState].
  bool get isSuccess => this is SuccessState<T>;

  /// Returns `true` if this state is [ErrorState].
  bool get isError => this is ErrorState<T>;

  /// Returns the current data if available, or `null`.
  T? get dataOrNull {
    final state = this;
    if (state is SuccessState<T>) return state.data;
    if (state is LoadingState<T>) return state.previousData;
    if (state is ErrorState<T>) return state.previousData;
    return null;
  }

  /// Returns the error object if in [ErrorState], or `null`.
  dynamic get errorOrNull {
    final state = this;
    if (state is ErrorState<T>) return state.error;
    return null;
  }

  /// Pattern matches over all possible states.
  R when<R>({
    required R Function() idle,
    required R Function(T? previousData) loading,
    required R Function(T data) success,
    required R Function(dynamic error, StackTrace? stackTrace, T? previousData) error,
  }) {
    final state = this;
    if (state is IdleState<T>) {
      return idle();
    } else if (state is LoadingState<T>) {
      return loading(state.previousData);
    } else if (state is SuccessState<T>) {
      return success(state.data);
    } else if (state is ErrorState<T>) {
      return error(state.error, state.stackTrace, state.previousData);
    }
    throw StateError('Unhandled state: $state');
  }

  /// Pattern matches with optional fallback for omitted states.
  R maybeWhen<R>({
    R Function()? idle,
    R Function(T? previousData)? loading,
    R Function(T data)? success,
    R Function(dynamic error, StackTrace? stackTrace, T? previousData)? error,
    required R Function() orElse,
  }) {
    final state = this;
    if (state is IdleState<T> && idle != null) {
      return idle();
    } else if (state is LoadingState<T> && loading != null) {
      return loading(state.previousData);
    } else if (state is SuccessState<T> && success != null) {
      return success(state.data);
    } else if (state is ErrorState<T> && error != null) {
      return error(state.error, state.stackTrace, state.previousData);
    }
    return orElse();
  }

  /// Transforms the underlying data of a success state.
  RequestState<R> mapData<R>(R Function(T data) transform) {
    final state = this;
    if (state is IdleState<T>) return RequestState<R>.idle();
    if (state is LoadingState<T>) {
      final prev = state.previousData != null ? transform(state.previousData as T) : null;
      return RequestState<R>.loading(previousData: prev);
    }
    if (state is SuccessState<T>) {
      return RequestState<R>.success(transform(state.data));
    }
    if (state is ErrorState<T>) {
      final prev = state.previousData != null ? transform(state.previousData as T) : null;
      return RequestState<R>.error(state.error, stackTrace: state.stackTrace, previousData: prev);
    }
    return RequestState<R>.idle();
  }
}

class IdleState<T> extends RequestState<T> {
  const IdleState();

  @override
  String toString() => 'RequestState<$T>.idle()';

  @override
  bool operator ==(Object other) => identical(this, other) || other is IdleState<T>;

  @override
  int get hashCode => runtimeType.hashCode;
}

class LoadingState<T> extends RequestState<T> {
  final T? previousData;

  const LoadingState({this.previousData});

  @override
  String toString() => 'RequestState<$T>.loading(previousData: $previousData)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LoadingState<T> && other.previousData == previousData);

  @override
  int get hashCode => Object.hash(runtimeType, previousData);
}

class SuccessState<T> extends RequestState<T> {
  final T data;

  const SuccessState(this.data);

  @override
  String toString() => 'RequestState<$T>.success(data: $data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SuccessState<T> && other.data == data);

  @override
  int get hashCode => Object.hash(runtimeType, data);
}

class ErrorState<T> extends RequestState<T> {
  final dynamic error;
  final StackTrace? stackTrace;
  final T? previousData;

  const ErrorState(this.error, {this.stackTrace, this.previousData});

  @override
  String toString() => 'RequestState<$T>.error(error: $error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ErrorState<T> &&
          other.error == error &&
          other.previousData == previousData);

  @override
  int get hashCode => Object.hash(runtimeType, error, previousData);
}
