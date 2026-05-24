import '../datasources/remote/auth_remote_datasource.dart';

class AuthRepositoryImpl {
  final AuthRemoteDataSource remote;

  AuthRepositoryImpl(this.remote);

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    await remote.login(phone: phone, password: password);
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    await remote.register(
      name: name,
      phone: phone,
      password: password,
    );
  }
}
