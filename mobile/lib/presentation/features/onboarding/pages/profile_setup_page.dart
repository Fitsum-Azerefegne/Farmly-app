import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import '../../auth/widgets/auth_button.dart';
import '../../chat/pages/chat_page.dart';

class ProfileSetupPage extends StatefulWidget {
  final String accessToken;
  final String fullName;
  final String phoneNumber;

  const ProfileSetupPage({
    super.key,
    required this.accessToken,
    required this.fullName,
    required this.phoneNumber,
  });

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _locationController = TextEditingController();
  final _cropController = TextEditingController();

  String _language = 'en';
  final List<String> _crops = [];
  bool _isLoading = false;

  bool get _isValid => _locationController.text.trim().length >= 2;

  void _addCrop() {
    final crop = _cropController.text.trim().toLowerCase();
    if (crop.isNotEmpty && !_crops.contains(crop)) {
      setState(() {
        _crops.add(crop);
        _cropController.clear();
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final body = jsonEncode({
        'full_name': widget.fullName,
        'phone_number': widget.phoneNumber,
        'location': _locationController.text.trim(),
        'preferred_language': _language,
        'user_type': 'aspiring',
        'years_experience': 0,
        'main_goal': 'increase_yield',
        'crops_grown': _crops,
      });

      http.Response? lastResp;
      for (final base in ['http://localhost:8000', 'http://10.0.2.2:8000']) {
        try {
          final resp = await http.post(
            Uri.parse('$base/api/onboarding/complete'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.accessToken}',
            },
            body: body,
          );
          lastResp = resp;
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => ChatPage(accessToken: widget.accessToken)),
              (_) => false,
            );
            return;
          }
        } catch (_) {}
      }

      if (!mounted) return;
      String msg = 'Failed to save profile';
      if (lastResp != null) {
        try {
          final d = jsonDecode(lastResp.body);
          msg = d['detail'] ?? d['message'] ?? lastResp.body;
        } catch (_) {}
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $msg')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.fromLTRB(36, 36, 36, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.04),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Set up your profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.darkPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Help us personalise your experience.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.muted),
                    ),
                    const SizedBox(height: 28),

                    // Language
                    _sectionLabel('Preferred Language'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _langButton('en', 'English')),
                        const SizedBox(width: 12),
                        Expanded(child: _langButton('am', 'አማርኛ')),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Location
                    _sectionLabel('Location'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                          hintText: 'e.g. Addis Ababa'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    // Crops
                    _sectionLabel('Crops Grown'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cropController,
                            decoration: const InputDecoration(
                                hintText: 'e.g. teff, maize'),
                            onSubmitted: (_) => _addCrop(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addCrop,
                          icon: const Icon(Icons.add_circle,
                              color: AppColors.primary, size: 32),
                        ),
                      ],
                    ),
                    if (_crops.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _crops
                            .map((c) => Chip(
                                  label: Text(c),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () =>
                                      setState(() => _crops.remove(c)),
                                  backgroundColor: AppColors.backgroundLight,
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 32),

                    _isLoading
                        ? const SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : AuthButton(
                            text: 'Finish Setup',
                            onPressed: _isValid ? _submit : null,
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.darkPrimary),
        ),
      );

  Widget _langButton(String value, String label) {
    final selected = _language == value;
    return GestureDetector(
      onTap: () => setState(() => _language = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: selected ? Colors.white : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
