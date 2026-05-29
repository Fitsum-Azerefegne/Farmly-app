import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_footer.dart';
import '../../onboarding/pages/onboarding_location_page.dart';
import '../../chat/pages/chat_page.dart';
import '../../../../data/datasources/local/auth_local_storage.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    phoneController.text = '';
  }

  String _formatLocal(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length <= 8 ? digits : digits.substring(0, 8);
    if (limited.length <= 4) return limited;
    return '${limited.substring(0, 4)}-${limited.substring(4)}';
  }

  Future<void> _onLoginPressed() async {
    final digits = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter an 8-digit phone number')));
      return;
    }
    final fullPhone = '2519$digits';
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });
    try {
      http.Response? lastResp;
      for (final base in apiBases) {
        try {
          final resp = await http.post(
            Uri.parse('$base/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone_number': fullPhone,
              'password': passwordController.text,
            }),
          );
          lastResp = resp;
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            if (!mounted) return;
            final data = jsonDecode(resp.body);
            final token = data['access_token'] as String;
            final user = data['user'] as Map<String, dynamic>;
            final onboardingDone = user['onboarding_completed'] == true;
            if (onboardingDone) {
              await AuthLocalStorage().saveToken(token);
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => ChatPage(accessToken: token)),
                (_) => false,
              );
            } else {
              await AuthLocalStorage().saveToken(token);
              final profile = await _loadProfile(token);
              final fullName = (user['full_name'] as String?) ??
                  (profile?['full_name'] as String?) ??
                  '';
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => OnboardingLocationPage(
                    accessToken: token,
                    fullName: fullName,
                    phoneNumber: fullPhone,
                  ),
                ),
              );
            }
            return;
          }
          // got a real response (4xx/5xx) — no need to try next base
          break;
        } catch (_) {
          // connection failed, try next base
        }
      }
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = (lastResp != null)
            ? 'Incorrect phone number or password.'
            : 'Unable to reach server. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _loadProfile(String token) async {
    for (final base in apiBases) {
      try {
        final resp = await http.get(
          Uri.parse('$base/api/users/me/profile'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (resp.statusCode == 200) {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        }
        break;
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          Positioned(
              top: -120, right: -100, child: _glowFromRGB(220, 252, 230)),
          Positioned(
              bottom: -160, left: -120, child: _glowFromRGB(232, 245, 233)),
          Center(
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
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.darkPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Log in to continue with Farmly.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 14, color: AppColors.muted),
                          ),
                          const SizedBox(height: 24),

                          // Phone input
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _hasError
                                    ? Colors.red
                                    : Colors.grey.shade300,
                                width: _hasError ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  child: const Text('+2519',
                                      style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600)),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: phoneController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: '0000-0000',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 14),
                                    ),
                                    onChanged: (v) {
                                      final formatted = _formatLocal(v);
                                      if (formatted != phoneController.text) {
                                        phoneController.value =
                                            TextEditingValue(
                                                text: formatted,
                                                selection:
                                                    TextSelection.collapsed(
                                                        offset:
                                                            formatted.length));
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            onChanged: (_) {
                              if (_hasError) {
                                setState(() {
                                  _hasError = false;
                                  _errorMessage = null;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Your password',
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _hasError
                                      ? Colors.red
                                      : Colors.grey.shade300,
                                  width: _hasError ? 1.5 : 1,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordPage()),
                              ),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          _isLoading
                              ? const SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                )
                              : AuthButton(
                                  text: 'Login',
                                  onPressed: _onLoginPressed,
                                ),

                          const SizedBox(height: 18),
                          Center(
                            child: AuthFooter(
                              text: 'New to Farmly? ',
                              actionText: 'Create an account',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterPage()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowFromRGB(int r, int g, int b) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Color.fromRGBO(r, g, b, 0.28),
            Color.fromRGBO(r, g, b, 0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
