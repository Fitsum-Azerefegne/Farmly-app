import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api.dart';
import '../../../data/models/user_model.dart';

class AuthRemoteDataSource {
  static const _bases = apiBases;

  Future<T> _post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    http.Response? lastResp;
    for (final base in _bases) {
      try {
        final resp = await http.post(
          Uri.parse('$base$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
        lastResp = resp;
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          return fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
        }
        // real HTTP error — don't try next base
        final detail = _extractDetail(resp);
        throw Exception(detail);
      } on Exception {
        rethrow;
      } catch (_) {
        // connection error — try next base
      }
    }
    if (lastResp != null) {
      throw Exception(_extractDetail(lastResp));
    }
    throw Exception('Unable to reach server. Check your connection.');
  }

  String _extractDetail(http.Response resp) {
    try {
      final d = jsonDecode(resp.body) as Map<String, dynamic>;
      final detail = d['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map) return first['msg']?.toString() ?? resp.body;
      }
      return d['message']?.toString() ?? 'Error ${resp.statusCode}';
    } catch (_) {
      return 'Error ${resp.statusCode}';
    }
  }

  /// Returns {access_token, user}
  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    return _post(
      '/api/auth/login',
      {'phone_number': phoneNumber, 'password': password},
      (json) => {
        'access_token': json['access_token'] as String,
        'user': UserModel.fromJson(json['user'] as Map<String, dynamic>),
      },
    );
  }

  /// Returns debug_otp (nullable)
  Future<String?> requestOtp({
    required String fullName,
    required String phoneNumber,
  }) async {
    return _post(
      '/api/auth/request-otp',
      {'full_name': fullName, 'phone_number': phoneNumber},
      (json) => json['debug_otp'] as String?,
    );
  }

  /// Returns setup_token
  Future<String> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    return _post(
      '/api/auth/verify-otp',
      {'phone_number': phoneNumber, 'otp_code': otpCode},
      (json) => json['setup_token'] as String,
    );
  }

  /// Returns {access_token, user}
  Future<Map<String, dynamic>> setPassword({
    required String phoneNumber,
    required String setupToken,
    required String password,
  }) async {
    return _post(
      '/api/auth/set-password',
      {
        'phone_number': phoneNumber,
        'setup_token': setupToken,
        'password': password,
      },
      (json) => {
        'access_token': json['access_token'] as String,
        'user': UserModel.fromJson(json['user'] as Map<String, dynamic>),
      },
    );
  }
}
