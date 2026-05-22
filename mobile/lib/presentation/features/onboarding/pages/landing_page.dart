import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/landing_buttons.dart';
import '../../auth/pages/register_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: Stack(
        children: [
          // BACKGROUND GLOWS
          Positioned(
            top: -120,
            right: -120,
            child: _glow(const Color(0xFF8BC34A)),
          ),
          Positioned(
            bottom: -180,
            left: -140,
            child: _glow(const Color(0xFFDCE775)),
          ),

          // CREATE ACCOUNT CARD
          Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: 400), // Same width as register
                child: Container(
                  padding: const EdgeInsets.fromLTRB(32, 48, 32, 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // LOGO
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.3),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.water_drop_rounded,
                          color: Colors.white,
                          size: 58,
                        ),
                      ),

                      const SizedBox(height: 28),
                      const Text(
                        'Farmly',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your AI Extension Worker',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17.5,
                          color: Color(0xFF667085),
                        ),
                      ),
                      const SizedBox(height: 48),

                      LandingButtons(
                        onRegister: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        onLogin: () {
                          context.read<OnboardingCubit>().navigateToLogin();
                        },
                        isLoading: false,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
