import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/onboarding_scaffold.dart';
import 'onboarding_farming_page.dart';

const _kLanguages = [
  {'code': 'en', 'label': 'English', 'tag': 'US'},
];

class OnboardingLanguagePage extends StatefulWidget {
  final String accessToken;
  final String fullName;
  final String phoneNumber;
  final String locationString;

  const OnboardingLanguagePage({
    super.key,
    required this.accessToken,
    required this.fullName,
    required this.phoneNumber,
    required this.locationString,
  });

  @override
  State<OnboardingLanguagePage> createState() => _OnboardingLanguagePageState();
}

class _OnboardingLanguagePageState extends State<OnboardingLanguagePage> {
  String _selected = 'en';

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingFarmingPage(
          accessToken: widget.accessToken,
          fullName: widget.fullName,
          phoneNumber: widget.phoneNumber,
          locationString: widget.locationString,
          language: _selected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 2,
      title: 'Choose Language',
      subtitle: 'Select your preferred language for Farmly.',
      icon: Icons.language_rounded,
      canContinue: true,
      onContinue: _continue,
      child: Column(
        children: _kLanguages.map((lang) {
          final selected = _selected == lang['code'];
          return GestureDetector(
            onTap: () => setState(() => _selected = lang['code']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.grey.shade200,
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                            color: Color.fromRGBO(27, 138, 62, 0.2),
                            blurRadius: 10,
                            offset: Offset(0, 4))
                      ]
                    : const [
                        BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.03),
                            blurRadius: 6,
                            offset: Offset(0, 2))
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color.fromRGBO(255, 255, 255, 0.2)
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(lang['tag']!,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color:
                                  selected ? Colors.white : AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(lang['label']!,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: selected ? Colors.white : AppColors.text)),
                  const Spacer(),
                  if (selected)
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 22),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
