import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api.dart';
import '../widgets/auth_button.dart';
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _step = 1;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _success = false;
  String? _errorMessage;
  String? _resetToken;
  String? _debugOtp;
  String _fullPhone = '';

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

  Future<void> _requestOtp() async {
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
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
      final resp =
          await _post('/api/auth/forgot-password', {'phone_number': _fullPhone});
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
        setState(() => _errorMessage =
            _extractError(resp, 'No account found with this number.'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      final resp = await _post('/api/auth/forgot-password/verify', {
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
          _resetToken = data['setup_token'];
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

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }
    if (_newPasswordController.text != _confirmController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final resp = await _post('/api/auth/reset-password', {
        'phone_number': _fullPhone,
        'reset_token': _resetToken,
        'new_password': _newPasswordController.text,
        'confirm_password': _confirmController.text,
      });
      if (!mounted) return;
      if (resp == null) {
        setState(
            () => _errorMessage = 'Unable to reach server. Please try again.');
        return;
      }
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (!mounted) return;
        setState(() => _success = true);
      } else {
        setState(() =>
            _errorMessage = _extractError(resp, 'Failed to reset password.'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                    if (_success) ..._successView(),
                    if (!_success) ...[
                      _stepIndicator(),
                      const SizedBox(height: 24),
                      if (_step == 1) ..._stepOne(),
                      if (_step == 2) ..._stepTwo(),
                      if (_step == 3) ..._stepThree(),
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
                                      : 'Reset Password',
                              onPressed: _step == 1
                                  ? _requestOtp
                                  : _step == 2
                                      ? _verifyOtp
                                      : _resetPassword,
                            ),
                    ],
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
        const Text('Forgot Password?',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.darkPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text("Enter your phone number and we'll send a reset code.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.muted)),
        const SizedBox(height: 24),
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
        const Text('Enter the Code',
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

  List<Widget> _successView() => [
        const SizedBox(height: 8),
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: 20),
        const Text('Password Reset!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.darkPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Your password has been changed successfully.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.muted)),
        const SizedBox(height: 28),
        AuthButton(
          text: 'Go to Login',
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
          ),
        ),
      ];

  List<Widget> _stepThree() => [
        const Text('New Password',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.darkPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Choose a strong new password.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.muted)),
        const SizedBox(height: 24),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            hintText: 'New password',
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          onChanged: (_) => _clearError(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            hintText: 'Confirm new password',
            suffixIcon: IconButton(
              icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          onChanged: (_) => _clearError(),
        ),
      ];
}
