import '../storage/storage.dart';

/// Manages retrieval, storage, and lifecycle of JWT authentication tokens.
class TokenManager {
  static const String _accessTokenKey = 'mvvm_auth_access_token';
  static const String _refreshTokenKey = 'mvvm_auth_refresh_token';
  static const String _expiryKey = 'mvvm_auth_token_expiry';

  final Storage storage;

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  DateTime? _cachedExpiry;

  TokenManager({required this.storage});

  /// Loads tokens from persistent storage into memory cache.
  Future<void> initialize() async {
    _cachedAccessToken = await storage.read(_accessTokenKey);
    _cachedRefreshToken = await storage.read(_refreshTokenKey);
    final expiryStr = await storage.read(_expiryKey);
    if (expiryStr != null) {
      _cachedExpiry = DateTime.tryParse(expiryStr);
    }
  }

  /// Returns the current access token, or `null`.
  String? get accessToken => _cachedAccessToken;

  /// Returns the current refresh token, or `null`.
  String? get refreshToken => _cachedRefreshToken;

  /// Returns `true` if an access token is present and not expired.
  bool get hasValidToken {
    if (_cachedAccessToken == null) return false;
    if (_cachedExpiry == null) return true;
    return DateTime.now().isBefore(_cachedExpiry!);
  }

  /// Saves the new access token and optional refresh token and expiry.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    DateTime? expiry,
  }) async {
    _cachedAccessToken = accessToken;
    await storage.write(_accessTokenKey, accessToken);

    if (refreshToken != null) {
      _cachedRefreshToken = refreshToken;
      await storage.write(_refreshTokenKey, refreshToken);
    }

    if (expiry != null) {
      _cachedExpiry = expiry;
      await storage.write(_expiryKey, expiry.toIso8601String());
    }
  }

  /// Clears all tokens from cache and persistent storage.
  Future<void> clearTokens() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedExpiry = null;

    await storage.delete(_accessTokenKey);
    await storage.delete(_refreshTokenKey);
    await storage.delete(_expiryKey);
  }
}
