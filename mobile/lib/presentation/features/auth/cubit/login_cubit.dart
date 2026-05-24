import 'package:flutter_bloc/flutter_bloc.dart';

class LoginState {
  final bool isLoading;

  LoginState({
    required this.isLoading,
  });

  factory LoginState.initial() {
    return LoginState(
      isLoading: false,
    );
  }

  LoginState copyWith({
    bool? isLoading,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginState.initial());

  Future<void> login() async {
    emit(state.copyWith(isLoading: true));

    await Future.delayed(const Duration(seconds: 2));

    emit(state.copyWith(isLoading: false));
  }
}
