import 'storage.dart';

/// Contract representing secure, encrypted key-value storage (such as iOS Keychain / Android Keystore).
abstract interface class SecureStorage implements Storage {}
