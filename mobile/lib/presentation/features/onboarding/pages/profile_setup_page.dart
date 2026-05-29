import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n.dart';
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
  final String _userType = 'aspiring';
  final String _mainGoal = 'increase_yield';
  final List<String> _crops = [];
  bool _isLoading = false;
  String? _error;

  bool get _isValid => _locationController.text.trim().length >= 2;

  @override
  void dispose() {
    _locationController.dispose();
    _cropController.dispose();
    super.dispose();
  }

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
    if (!_isValid) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final body = jsonEncode({
      'full_name': widget.fullName,
      'phone_number': widget.phoneNumber,
      'location': _locationController.text.trim(),
      'preferred_language': _language,
      'user_type': _userType,
      'years_experience': 0,
      'main_goal': _mainGoal,
      'crops_grown': _crops,
    });

    http.Response? lastResp;
    try {
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
          if (!mounted) return;
          break; // got a real HTTP error, don't try next base
        } catch (_) {
          // connection failed, try next base
        }
      }

      if (!mounted) return;
      String msg = 'Failed to save profile.';
      if (lastResp != null) {
        try {
          final d = jsonDecode(lastResp.body);
          msg = (d['detail'] is String ? d['detail'] : null) ??
              (d['message'] is String ? d['message'] : null) ??
              'Error ${lastResp.statusCode}';
        } catch (_) {}
      } else {
        msg = 'Unable to reach server. Check your connection.';
      }
      if (!mounted) return;
      setState(() {
        _error = msg;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    I18n.t('setup_profile_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.darkPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    I18n.t('setup_profile_sub'),
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 14, color: AppColors.muted),
                  ),
                  const SizedBox(height: 28),

                  // Language
                  _sectionLabel(I18n.t('preferred_language')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _langButton('en', 'English')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Location
                  _sectionLabel(I18n.t('location_label')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    decoration:
                        const InputDecoration(hintText: 'e.g. Addis Ababa'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // Crops (optional)
                  _sectionLabel(I18n.t('crops_grown_optional')),
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

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13)),
                          ),
                        ],
                      ),
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
                          text: I18n.t('finish_setup'),
                          onPressed: _isValid ? _submit : null,
                        ),
                ],
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
