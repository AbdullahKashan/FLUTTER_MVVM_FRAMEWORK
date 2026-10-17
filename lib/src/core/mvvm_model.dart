import 'package:flutter/foundation.dart';

/// Base interface for models within the `flutter_mvvm_framework`.
@immutable
abstract class MvvmModel {
  const MvvmModel();

  /// Converts this model instance into a JSON-compatible map.
  Map<String, dynamic> toJson();

  @override
  String toString() => '$runtimeType(${toJson()})';
}
