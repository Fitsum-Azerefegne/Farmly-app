import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class OnboardingScaffold extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool canContinue;
  final VoidCallback onContinue;
  final String continueLabel;
  final Widget child;

  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.canContinue,
    required this.onContinue,
    required this.child,
    this.continueLabel = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBF4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.darkPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Step indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final active = i + 1 == step;
                      final done = i + 1 < step;
                      return Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: active ? 32 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: (active || done)
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          if (i < 2) const SizedBox(width: 6),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B8A3E), Color(0xFF006B2D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(27, 138, 62, 0.25),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),

                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkPrimary)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.muted, height: 1.4)),
                  const SizedBox(height: 28),

                  // Content
                  SizedBox(width: double.infinity, child: child),
                  const SizedBox(height: 32),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: AnimatedOpacity(
                      opacity: canContinue ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: 150),
                      child: ElevatedButton(
                        onPressed: canContinue ? onContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                          elevation: 0,
                        ),
                        child: Text(continueLabel,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
