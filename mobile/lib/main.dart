import 'package:flutter/material.dart';
import 'presentation/features/onboarding/pages/splash_page.dart';
import 'app/theme.dart';
import 'app/injection_container.dart';

void main() {
  InjectionContainer.init();
  runApp(const FarmlyApp());
}

class FarmlyApp extends StatelessWidget {
  const FarmlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Farmly',
      theme: AppTheme.light(),
      home: const SplashPage(),
    );
  }
}
