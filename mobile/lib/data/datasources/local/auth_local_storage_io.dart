import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class AuthLocalStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'access_token';

  Future<void> saveToken(String token) async =>
      await _storage.write(key: _keyToken, value: token).then((_) {
    debugPrint('AuthLocalStorage (io): saved token length=${token.length}');
  });

  Future<String?> readToken() async {
    final v = await _storage.read(key: _keyToken);
    debugPrint('AuthLocalStorage (io): read token ${v == null ? "null" : "length=${v.length}"}');
    return v;
  }

  Future<void> deleteToken() async => await _storage.delete(key: _keyToken).then((_) {
        debugPrint('AuthLocalStorage (io): deleted token');
      });
}
