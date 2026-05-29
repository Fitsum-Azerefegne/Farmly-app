import '../datasources/remote/auth_remote_datasource.dart';

class AuthRepositoryImpl {
  final AuthRemoteDataSource remote;

  AuthRepositoryImpl(this.remote);

  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) {
    return remote.login(phoneNumber: phoneNumber, password: password);
  }

  Future<String?> requestOtp({
    required String fullName,
    required String phoneNumber,
  }) {
    return remote.requestOtp(fullName: fullName, phoneNumber: phoneNumber);
  }

  Future<String> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) {
    return remote.verifyOtp(phoneNumber: phoneNumber, otpCode: otpCode);
  }

  Future<Map<String, dynamic>> setPassword({
    required String phoneNumber,
    required String setupToken,
    required String password,
  }) {
    return remote.setPassword(
      phoneNumber: phoneNumber,
      setupToken: setupToken,
      password: password,
    );
  }
}
