import 'dart:convert';

/// Abstract key-value storage contract used by auth and data caching layers.
abstract interface class Storage {
  /// Reads a string value for the given [key], or returns `null` if not found.
  Future<String?> read(String key);

  /// Writes a string [value] associated with the given [key].
  Future<void> write(String key, String value);

  /// Deletes the entry for the given [key].
  Future<void> delete(String key);

  /// Clears all entries from the storage.
  Future<void> clear();

  /// Returns `true` if the given [key] exists in storage.
  Future<bool> containsKey(String key);

  /// Reads and deserializes a JSON map stored at [key].
  Future<Map<String, dynamic>?> readJson(String key);

  /// Serializes and writes a JSON [map] to the given [key].
  Future<void> writeJson(String key, Map<String, dynamic> map);
}

/// An in-memory implementation of [Storage] ideal for testing, previews, and session caching.
class MemoryStorage implements Storage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = _data[key];
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeJson(String key, Map<String, dynamic> map) async {
    _data[key] = jsonEncode(map);
  }
}
