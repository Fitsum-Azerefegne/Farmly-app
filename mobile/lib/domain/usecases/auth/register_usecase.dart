import '../../../data/repositories/auth_repository_impl.dart';

class RegisterUseCase {
  final AuthRepositoryImpl repository;

  RegisterUseCase(this.repository);

  Future<void> call({
    required String name,
    required String phone,
    required String password,
  }) async {
    await repository.register(
      name: name,
      phone: phone,
      password: password,
    );
  }
}
