import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingState {
  final bool isLoading;
  final String? errorMessage;

  OnboardingState({
    required this.isLoading,
    this.errorMessage,
  });

  factory OnboardingState.initial() {
    return OnboardingState(
      isLoading: false,
      errorMessage: null,
    );
  }

  OnboardingState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return OnboardingState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(OnboardingState.initial());

  Future<void> navigateToRegister() async {
    emit(state.copyWith(isLoading: true));
    await Future.delayed(const Duration(milliseconds: 300));
    emit(state.copyWith(isLoading: false));
  }

  Future<void> navigateToLogin() async {
    emit(state.copyWith(isLoading: true));
    await Future.delayed(const Duration(milliseconds: 300));
    emit(state.copyWith(isLoading: false));
  }
}
