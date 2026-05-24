class AuthRemoteDataSource {
  Future<void> login({
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
  }
}
