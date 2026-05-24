import '../presentation/features/auth/cubit/auth_cubit.dart';

class InjectionContainer {
  static late AuthCubit authCubit;

  static void init() {
    authCubit = AuthCubit();
  }
}
