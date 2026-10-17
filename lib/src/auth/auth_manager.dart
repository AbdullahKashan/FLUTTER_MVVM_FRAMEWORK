import 'dart:async';
import 'package:flutter/foundation.dart';
import '../storage/storage.dart';
import 'token_manager.dart';

/// Central coordinator for authentication state, login, logout, and token refreshes.
class AuthManager extends ChangeNotifier {
  final TokenManager _tokenManager;
  final Future<String> Function(String refreshToken)? refreshHandler;

  bool _isAuthenticated = false;
  Completer<String>? _refreshCompleter;

  AuthManager({
    required Storage storage,
    this.refreshHandler,
  }) : _tokenManager = TokenManager(storage: storage);

  /// Underlying token manager instance.
  TokenManager get tokenManager => _tokenManager;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => _isAuthenticated;

  /// Initializes the auth manager and verifies cached session state.
  Future<void> initialize() async {
    await _tokenManager.initialize();
    _isAuthenticated = _tokenManager.hasValidToken;
    notifyListeners();
  }

  /// Logs the user in by saving the received tokens.
  Future<void> login({
    required String accessToken,
    String? refreshToken,
    DateTime? expiry,
  }) async {
    await _tokenManager.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiry: expiry,
    );
    _isAuthenticated = true;
    notifyListeners();
  }

  /// Logs the user out and clears all session data.
  Future<void> logout() async {
    await _tokenManager.clearTokens();
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Refreshes the access token using a concurrency mutex.
  ///
  /// If multiple requests fail with 401 simultaneously, only one refresh request
  /// is dispatched. All other callers await the same in-flight [Completer].
  Future<String> refreshToken() async {
    if (refreshHandler == null) {
      throw Exception('No token refresh handler configured in AuthManager.');
    }

    final currentRefreshToken = _tokenManager.refreshToken;
    if (currentRefreshToken == null) {
      await logout();
      throw Exception('No refresh token available.');
    }

    // Concurrency mutex check
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<String>();
    _refreshCompleter = completer;

    try {
      final newAccessToken = await refreshHandler!(currentRefreshToken);
      await _tokenManager.saveTokens(accessToken: newAccessToken);
      completer.complete(newAccessToken);
      return newAccessToken;
    } catch (e) {
      completer.completeError(e);
      await logout();
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }
}
