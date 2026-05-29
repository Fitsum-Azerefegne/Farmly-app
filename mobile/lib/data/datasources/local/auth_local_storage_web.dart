// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class AuthLocalStorage {
  static const _keyToken = 'access_token';

  Future<void> saveToken(String token) async {
    html.window.localStorage[_keyToken] = token;
    debugPrint('AuthLocalStorage (web): saved token length=${token.length}');
  }

  Future<String?> readToken() async {
    final v = html.window.localStorage[_keyToken];
    debugPrint('AuthLocalStorage (web): read token ${v == null ? "null" : "length=${v.length}"}');
    return v;
  }

  Future<void> deleteToken() async {
    html.window.localStorage.remove(_keyToken);
    debugPrint('AuthLocalStorage (web): deleted token');
  }
}
