import '../../../data/repositories/auth_repository_impl.dart';

class LoginUseCase {
  final AuthRepositoryImpl repository;

  LoginUseCase(this.repository);

  Future<void> call({
    required String phone,
    required String password,
  }) async {
    await repository.login(phone: phone, password: password);
  }
}
