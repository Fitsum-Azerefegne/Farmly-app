import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    try {
      emit(AuthLoading());

      await Future.delayed(const Duration(seconds: 1));

      emit(LoginSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    try {
      emit(AuthLoading());

      await Future.delayed(const Duration(seconds: 1));

      emit(RegisterSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
