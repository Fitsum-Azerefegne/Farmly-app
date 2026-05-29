class UserEntity {
  final String userId;
  final String? fullName;
  final String phoneNumber;
  final bool onboardingCompleted;

  UserEntity({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.onboardingCompleted,
  });
}
