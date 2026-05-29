import '../../../data/repositories/auth_repository_impl.dart';

class RegisterUseCase {
  final AuthRepositoryImpl repository;
  RegisterUseCase(this.repository);

  Future<String?> requestOtp({
    required String fullName,
    required String phoneNumber,
  }) {
    return repository.requestOtp(fullName: fullName, phoneNumber: phoneNumber);
  }

  Future<String> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) {
    return repository.verifyOtp(phoneNumber: phoneNumber, otpCode: otpCode);
  }

  Future<Map<String, dynamic>> setPassword({
    required String phoneNumber,
    required String setupToken,
    required String password,
  }) {
    return repository.setPassword(
      phoneNumber: phoneNumber,
      setupToken: setupToken,
      password: password,
    );
  }
}
