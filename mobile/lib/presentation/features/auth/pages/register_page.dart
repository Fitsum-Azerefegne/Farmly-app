import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api.dart';
import '../../../../data/datasources/local/auth_local_storage.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_footer.dart';
import '../../onboarding/pages/onboarding_location_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _step = 1;

  // step 1
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // step 2
  final _otpController = TextEditingController();
  String? _debugOtp;

  // step 3
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;
  String? _errorMessage;
  String _fullPhone = '';
  String? _setupToken;

  // ── helpers ──────────────────────────────────────────────

  String _formatLocal(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length <= 8 ? digits : digits.substring(0, 8);
    if (limited.length <= 4) return limited;
    return '${limited.substring(0, 4)}-${limited.substring(4)}';
  }

  Future<http.Response?> _post(String path, Map<String, dynamic> body) async {
    for (final base in apiBases) {
      try {
        final resp = await http.post(
          Uri.parse('$base$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
        return resp;
      } catch (_) {}
    }
    return null;
  }

  String _extractError(http.Response resp, String fallback) {
    try {
      final d = jsonDecode(resp.body);
      return d['detail'] ?? d['message'] ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  // ── step 1: request OTP ──────────────────────────────────

  Future<void> _requestOtp() async {
    final name = _nameController.text.trim();
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (name.length < 2) {
      setState(() => _errorMessage = 'Please enter your full name.');
      return;
    }
    if (digits.length != 8) {
      setState(
          () => _errorMessage = 'Please enter a valid 8-digit phone number.');
      return;
    }
    _fullPhone = '2519$digits';
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final resp = await _post('/api/auth/request-otp', {
        'full_name': name,
        'phone_number': _fullPhone,
      });
      if (!mounted) return;
      if (resp == null) {
        setState(
            () => _errorMessage = 'Unable to reach server. Please try again.');
        return;
      }
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        setState(() {
          _debugOtp = data['debug_otp'];
          _step = 2;
          _errorMessage = null;
        });
      } else {
        setState(
            () => _errorMessage = _extractError(resp, 'Failed to send OTP.'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── step 2: verify OTP ───────────────────────────────────

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length < 4) {
      setState(() => _errorMessage = 'Please enter the OTP code.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final resp = await _post('/api/auth/verify-otp', {
        'phone_number': _fullPhone,
        'otp_code': _otpController.text.trim(),
      });
      if (!mounted) return;
      if (resp == null) {
        setState(
            () => _errorMessage = 'Unable to reach server. Please try again.');
        return;
      }
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        setState(() {
          _setupToken = data['setup_token'];
          _step = 3;
          _errorMessage = null;
        });
      } else {
        setState(() =>
            _errorMessage = _extractError(resp, 'Invalid or expired OTP.'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── step 3: set password ─────────────────────────────────

  Future<void> _setPassword() async {
    if (_passwordController.text.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final resp = await _post('/api/auth/set-password', {
        'phone_number': _fullPhone,
        'setup_token': _setupToken,
        'password': _passwordController.text,
      });
      if (!mounted) return;
      if (resp == null) {
        setState(
            () => _errorMessage = 'Unable to reach server. Please try again.');
        return;
      }
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        final token = data['access_token'] as String;
        await AuthLocalStorage().saveToken(token);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OnboardingLocationPage(
              accessToken: token,
              fullName: _nameController.text.trim(),
              phoneNumber: _fullPhone,
            ),
          ),
        );
      } else {
        setState(() =>
            _errorMessage = _extractError(resp, 'Failed to create account.'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkPrimary),
          onPressed: () {
            if (_step > 1) {
              setState(() {
                _step--;
                _errorMessage = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    _stepIndicator(),
                    const SizedBox(height: 24),

                    if (_step == 1) ..._stepOne(),
                    if (_step == 2) ..._stepTwo(),

                    // step 3 — kept in tree always to preserve TextField state
                    Visibility(
                      visible: _step == 3,
                      maintainState: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Set your password',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.darkPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          const Text(
                              'Choose a strong password for your account.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14, color: AppColors.muted)),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              hintText: 'Confirm password',
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_errorMessage!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    _isLoading
                        ? const SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : AuthButton(
                            text: _step == 1
                                ? 'Send Code'
                                : _step == 2
                                    ? 'Verify Code'
                                    : 'Create Account',
                            onPressed: _step == 1
                                ? _requestOtp
                                : _step == 2
                                    ? _verifyOtp
                                    : _setPassword,
                          ),
                    const SizedBox(height: 16),
                    if (_step == 1)
                      AuthFooter(
                        text: 'Already have an account? ',
                        actionText: 'Login',
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        ),
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

  Widget _stepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i + 1 == _step;
        final done = i + 1 < _step;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 28 : 10,
              height: 10,
              decoration: BoxDecoration(
                color:
                    (active || done) ? AppColors.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            if (i < 2) const SizedBox(width: 6),
          ],
        );
      }),
    );
  }

  List<Widget> _stepOne() => [
        const Text('Create account',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.darkPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Join Farmly in seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.muted)),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'Full name'),
          onChanged: (_) => _clearError(),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: const Text('+2519',
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '0000-0000',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  onChanged: (v) {
                    final formatted = _formatLocal(v);
                    if (formatted != _phoneController.text) {
                      _phoneController.value = TextEditingValue(
                        text: formatted,
                        selection:
                            TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                    _clearError();
                  },
                ),
              ),
            ],
          ),
        ),
      ];

  List<Widget> _stepTwo() => [
        const Text('Verify your number',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.darkPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('We sent a code to +2519${_phoneController.text}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        if (_debugOtp != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bug_report,
                    size: 14, color: Color(0xFFF57F17)),
                const SizedBox(width: 6),
                Text('Dev OTP: $_debugOtp',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF57F17))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 10),
          decoration: InputDecoration(
            counterText: '',
            hintText: '------',
            hintStyle:
                TextStyle(letterSpacing: 10, color: Colors.grey.shade400),
          ),
          onChanged: (_) => _clearError(),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _isLoading ? null : _requestOtp,
          child: const Text('Resend code',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ];
}
