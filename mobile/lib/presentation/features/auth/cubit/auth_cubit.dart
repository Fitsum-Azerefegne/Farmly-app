import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> register({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    try {
      emit(AuthLoading());

      await Future.delayed(const Duration(seconds: 2));

      emit(AuthSuccess());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}
