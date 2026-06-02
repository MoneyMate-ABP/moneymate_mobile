import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'key_value_storage.dart';

class SecureKeyValueStorage implements KeyValueStorage {
  SecureKeyValueStorage({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }

  @override
  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }
}
