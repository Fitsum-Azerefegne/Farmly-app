import '../data/datasources/remote/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/usecases/auth/login_usecase.dart';
import '../domain/usecases/auth/register_usecase.dart';

class InjectionContainer {
  static late AuthRemoteDataSource authRemoteDataSource;
  static late AuthRepositoryImpl authRepository;
  static late LoginUseCase loginUseCase;
  static late RegisterUseCase registerUseCase;

  static void init() {
    authRemoteDataSource = AuthRemoteDataSource();
    authRepository = AuthRepositoryImpl(authRemoteDataSource);
    loginUseCase = LoginUseCase(authRepository);
    registerUseCase = RegisterUseCase(authRepository);
  }
}
