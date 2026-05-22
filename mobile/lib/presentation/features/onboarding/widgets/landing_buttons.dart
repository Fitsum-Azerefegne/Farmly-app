import 'package:flutter/material.dart';

class LandingButtons extends StatelessWidget {
  final VoidCallback onRegister;
  final VoidCallback onLogin;
  final bool isLoading;

  const LandingButtons({
    super.key,
    required this.onRegister,
    required this.onLogin,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary action: Register (solid green button)
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading ? null : onRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text("Register"),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary action: Login (outlined button)
        SizedBox(
          height: 54,
          child: OutlinedButton(
            onPressed: isLoading ? null : onLogin,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
            ),
            child: const Text("Login"),
          ),
        ),
      ],
    );
  }
}
