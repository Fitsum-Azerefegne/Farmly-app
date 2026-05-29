import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.userId,
    required super.fullName,
    required super.phoneNumber,
    required super.onboardingCompleted,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'onboarding_completed': onboardingCompleted,
    };
  }
}
