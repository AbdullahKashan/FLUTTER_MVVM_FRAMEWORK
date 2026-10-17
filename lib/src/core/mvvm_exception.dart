/// Base exception class for all errors originating within `flutter_mvvm_framework`.
class MvvmException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// Optional underlying cause or error object.
  final dynamic cause;

  /// Optional stack trace captured when the exception occurred.
  final StackTrace? stackTrace;

  const MvvmException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() {
    if (cause != null) {
      return 'MvvmException: $message (Caused by: $cause)';
    }
    return 'MvvmException: $message';
  }
}

/// Thrown when an operation is attempted on a ViewModel that has already been disposed.
class ViewModelDisposedException extends MvvmException {
  const ViewModelDisposedException([super.message = 'Cannot execute action on a disposed ViewModel.']);
}

/// Thrown when an expected service or dependency is missing from the ServiceLocator.
class DependencyNotFoundException extends MvvmException {
  const DependencyNotFoundException(Type type)
      : super('No instance registered for type $type in ServiceLocator.');
}

/// Thrown when a Command execution fails or is triggered when canExecute is false.
class CommandExecutionException extends MvvmException {
  const CommandExecutionException(super.message, {super.cause, super.stackTrace});
}
