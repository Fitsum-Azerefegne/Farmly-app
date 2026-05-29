import '../../../data/repositories/auth_repository_impl.dart';

class LoginUseCase {
  final AuthRepositoryImpl repository;
  LoginUseCase(this.repository);

  Future<Map<String, dynamic>> call({
    required String phoneNumber,
    required String password,
  }) {
    return repository.login(phoneNumber: phoneNumber, password: password);
  }
}
