import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_colors.dart';

class SetPasswordPage extends StatefulWidget {
  final String phone;
  final String? setupToken;

  const SetPasswordPage({super.key, required this.phone, this.setupToken});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  Future<void> _submit() async {
    final p = passwordController.text.trim();
    final c = confirmController.text.trim();
    if (p.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password must be at least 6 characters')));
      return;
    }
    if (p != c) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final candidates = ['http://localhost:8000', 'http://10.0.2.2:8000'];
      http.Response? lastResp;
      for (final base in candidates) {
        final uri = widget.setupToken == null
            ? Uri.parse('$base/api/auth/register-no-otp')
            : Uri.parse('$base/api/auth/set-password');
        try {
          final body = widget.setupToken == null
              ? jsonEncode({
                  'full_name': '',
                  'phone_number': widget.phone,
                  'password': p
                })
              : jsonEncode({
                  'phone_number': widget.phone,
                  'setup_token': widget.setupToken,
                  'password': p
                });
          final resp = await http.post(uri,
              headers: {'Content-Type': 'application/json'}, body: body);
          lastResp = resp;
          if (resp.statusCode == 201 ||
              (resp.statusCode >= 200 && resp.statusCode < 300)) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Account created. You can now login.')));
            if (!mounted) return;
            Navigator.popUntil(context, (route) => route.isFirst);
            return;
          }
        } catch (_) {}
      }
      if (!mounted) return;
      if (lastResp != null) {
        String msg = 'Failed to set password';
        try {
          final d = jsonDecode(lastResp.body);
          msg = d['detail'] ?? d['message'] ?? lastResp.body;
        } catch (_) {}
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $msg')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Unable to reach backend')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Set a password',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: _obscure,
                    decoration:
                        const InputDecoration(hintText: 'Confirm password'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Set password')),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
