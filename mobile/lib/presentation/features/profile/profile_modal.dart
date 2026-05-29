import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/auth_local_storage.dart';
import '../../shared/app_button.dart';
import '../../../core/toast.dart';

class ProfileModal extends StatefulWidget {
  final String accessToken;
  const ProfileModal({super.key, required this.accessToken});

  @override
  State<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<ProfileModal> {
  final _full = TextEditingController();
  final _phone = TextEditingController();
  String _lang = 'en';
  bool _loading = true;
  bool _saving = false;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${widget.accessToken}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      for (final base in apiBases) {
        final r = await http.get(Uri.parse('$base/api/users/me/profile'),
            headers: _headers);
        if (r.statusCode == 200) {
          final d = jsonDecode(r.body);
          _full.text = d['full_name'] ?? '';
          _phone.text = d['phone_number'] ?? '';
          _lang = d['preferred_language'] ?? 'en';
          break;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    var saved = false;
    try {
      for (final base in apiBases) {
        final r = await http.patch(Uri.parse('$base/api/users/me/profile'),
            headers: _headers,
            body: jsonEncode({
              'full_name': _full.text.trim(),
              'preferred_language': _lang,
            }));
        if (r.statusCode == 200) {
          // language persistence removed; keep server value
          saved = true;
          break;
        }
      }
    } catch (_) {}
    if (saved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Toast.show(context, 'Profile updated');
      });
    }
    if (mounted) setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _logout() async {
    await AuthLocalStorage().deleteToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Toast.show(context, 'Logged out');
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Profile',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _full,
                      decoration:
                          const InputDecoration(labelText: 'Full name')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _phone,
                      decoration:
                          const InputDecoration(labelText: 'Phone number'),
                      enabled: false),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _lang == 'en' ? 'en' : 'en',
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (v) => setState(() => _lang = v ?? 'en'),
                    decoration: const InputDecoration(labelText: 'Language'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          onPressed: _saving ? null : _save,
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(_saving ? '...' : 'Save'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          onPressed: _logout,
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.darkPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: const Text('Logout'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
      ),
    );
  }
}
