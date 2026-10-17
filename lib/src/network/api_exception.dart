import '../core/mvvm_exception.dart';

/// Base class for all network-related exceptions.
abstract class ApiException extends MvvmException {
  /// The HTTP status code, if available.
  final int? statusCode;

  /// The raw response body string, if available.
  final String? responseBody;

  const ApiException(
    super.message, {
    this.statusCode,
    this.responseBody,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return '$runtimeType [$statusCode]: $message';
    }
    return '$runtimeType: $message';
  }
}

/// Thrown on HTTP 400 Bad Request.
class BadRequestException extends ApiException {
  const BadRequestException(
    super.message, {
    super.statusCode = 400,
    super.responseBody,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown on HTTP 401 Unauthorized.
class UnauthorizedException extends ApiException {
  const UnauthorizedException(
    super.message, {
    super.statusCode = 401,
    super.responseBody,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown on HTTP 403 Forbidden.
class ForbiddenException extends ApiException {
  const ForbiddenException(
    super.message, {
    super.statusCode = 403,
    super.responseBody,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown on HTTP 404 Not Found.
class NotFoundException extends ApiException {
  const NotFoundException(
    super.message, {
    super.statusCode = 404,
    super.responseBody,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown on HTTP 422 Unprocessable Entity or validation errors.
class ValidationException extends ApiException {
  /// Key-value mapping of field names to their specific validation error messages.
  final Map<String, List<String>> errors;

  const ValidationException(
    super.message, {
    super.statusCode = 422,
    super.responseBody,
    this.errors = const {},
    super.cause,
    super.stackTrace,
  });

  /// Retrieves the first error message for a given [field], or `null`.
  String? firstErrorFor(String field) {
    final list = errors[field];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }
}

/// Thrown on HTTP 5xx Server Errors.
class ServerException extends ApiException {
  const ServerException(
    super.message, {
    super.statusCode = 500,
    super.responseBody,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when a network request times out.
class TimeoutException extends ApiException {
  const TimeoutException(
    super.message, {
    super.statusCode,
    super.responseBody,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown on low-level transport errors (e.g. no internet connection, DNS failure).
class NetworkException extends ApiException {
  const NetworkException(
    super.message, {
    super.statusCode,
    super.responseBody,
    super.cause,
    super.stackTrace,
  });
}
