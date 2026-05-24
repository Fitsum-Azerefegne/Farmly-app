import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class LoginForm extends StatelessWidget {
  final bool isLoading;

  const LoginForm({
    super.key,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PHONE FIELD
        TextField(
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+251 91 123 4567',
            labelText: 'Phone Number',
            labelStyle: const TextStyle(
              color: AppColors.muted,
            ),
            hintStyle: const TextStyle(
              color: AppColors.mutedLight,
            ),
            filled: true,
            fillColor: const Color.fromRGBO(255, 255, 255, 0.75),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.success,
                width: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // PASSWORD FIELD
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            hintText: '••••••••',
            labelText: 'Password',
            labelStyle: const TextStyle(
              color: AppColors.muted,
            ),
            hintStyle: const TextStyle(
              color: AppColors.mutedLight,
            ),
            filled: true,
            fillColor: const Color.fromRGBO(255, 255, 255, 0.75),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.success,
                width: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // FORGOT PASSWORD
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text(
              "Forgot Password?",
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // LOGIN BUTTON
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: isLoading ? null : () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              elevation: 10,
              shadowColor: const Color.fromRGBO(46, 125, 50, 0.28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 28),

        // REGISTER LINK
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(
                color: AppColors.muted,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                "Register",
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
