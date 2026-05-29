// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/auth_local_storage.dart';
import '../../shared/app_button.dart';
import '../../../core/i18n.dart';
import '../../../core/toast.dart';

class ProfileSidebar extends StatefulWidget {
  final String accessToken;
  final VoidCallback onClose;
  const ProfileSidebar({super.key, required this.accessToken, required this.onClose});

  @override
  State<ProfileSidebar> createState() => _ProfileSidebarState();
}

class _ProfileSidebarState extends State<ProfileSidebar> {
  final _formKey = GlobalKey<FormState>();
  final _full = TextEditingController();
  final _phone = TextEditingController();
  final _farmer = TextEditingController();
  final _location = TextEditingController();
  final _cropController = TextEditingController();
  final List<String> _crops = [];
  String? _userType;
  int _years = 0;
  String? _mainGoal;
  String _lang = I18n.lang;
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
        final r = await http.get(Uri.parse('$base/api/users/me/profile'), headers: _headers);
        if (r.statusCode == 200) {
          final d = jsonDecode(r.body);
          _full.text = d['full_name'] ?? '';
          _phone.text = d['phone_number'] ?? '';
          _farmer.text = (d['farmer_details'] as String?) ?? '';
          _location.text = d['location'] ?? '';
          _userType = d['user_type'] as String?;
          _years = (d['years_experience'] is int)
              ? d['years_experience'] as int
              : (d['years_experience'] is String ? int.tryParse(d['years_experience']) ?? 0 : 0);
          _mainGoal = d['main_goal'] as String?;
          final crops = d['crops_grown'];
          if (crops is List) {
            _crops.clear();
            for (final c in crops) {
              if (c is String) _crops.add(c);
            }
          }
          _lang = d['preferred_language'] ?? I18n.lang;
          break;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    var saved = false;
    try {
      for (final base in apiBases) {
        final r = await http.patch(Uri.parse('$base/api/users/me/profile'), headers: _headers, body: jsonEncode({
          'full_name': _full.text.trim(),
          'farmer_details': _farmer.text.trim(),
          'location': _location.text.trim(),
          'preferred_language': _lang,
          'user_type': _userType,
          'years_experience': _years,
          'main_goal': _mainGoal,
          'crops_grown': _crops,
        }));
        if (r.statusCode == 200) {
          await I18n.setLanguage(_lang);
          saved = true;
          break;
        }
      }
    } catch (_) {}
    if (saved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Toast.showTranslated(context, 'profile_updated');
      });
    }
    if (mounted) setState(() => _saving = false);
    if (mounted) widget.onClose();
  }

  Future<void> _logout() async {
    try {
      await AuthLocalStorage().deleteToken();
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Toast.showTranslated(context, 'logout_success');
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelW = width < 600 ? width * 0.9 : 380.0;

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: SizedBox(
          width: panelW,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: widget.onClose,
                            child: const Icon(Icons.chevron_left, size: 28),
                          ),
                          const SizedBox(width: 8),
                          Text(I18n.t('profile_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: const Color.fromRGBO(27, 138, 62, 0.08),
                                  child: const Icon(Icons.eco, size: 36, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _full,
                                decoration: InputDecoration(labelText: I18n.t('full_name')),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phone,
                                decoration: InputDecoration(labelText: I18n.t('phone_number')),
                                enabled: false,
                              ),
                              const SizedBox(height: 8),
                              // Farmer/onboarding fields
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: ['aspiring', 'beginner', 'experienced', 'explorer']
                                        .contains(_userType)
                                    ? _userType
                                    : null,
                                items: const [
                                  DropdownMenuItem(value: 'aspiring', child: Text('Aspiring farmer')),
                                  DropdownMenuItem(value: 'beginner', child: Text('Beginner farmer')),
                                  DropdownMenuItem(value: 'experienced', child: Text('Experienced farmer')),
                                  DropdownMenuItem(value: 'explorer', child: Text('Explorer')),
                                ],
                                onChanged: (v) => setState(() => _userType = v),
                                decoration: const InputDecoration(labelText: 'Farmer type'),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: _years.toString(),
                                decoration: const InputDecoration(labelText: 'Years of experience'),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => _years = int.tryParse(v) ?? 0,
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: [
                                  'increase_yield',
                                  'reduce_costs',
                                  'sustainable_farming',
                                  'organic_farming',
                                  'market_access'
                                ].contains(_mainGoal)
                                    ? _mainGoal
                                    : null,
                                items: const [
                                  DropdownMenuItem(value: 'increase_yield', child: Text('Increase crop yield')),
                                  DropdownMenuItem(value: 'reduce_costs', child: Text('Reduce farming costs')),
                                  DropdownMenuItem(value: 'sustainable_farming', child: Text('Sustainable farming')),
                                  DropdownMenuItem(value: 'organic_farming', child: Text('Organic farming')),
                                  DropdownMenuItem(value: 'market_access', child: Text('Better market access')),
                                ],
                                onChanged: (v) => setState(() => _mainGoal = v),
                                decoration: const InputDecoration(labelText: 'Main goal'),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _cropController,
                                decoration: const InputDecoration(labelText: 'Crops grown (comma separated)'),
                                onFieldSubmitted: (v) {
                                  final c = v.trim().toLowerCase();
                                  if (c.isNotEmpty && !_crops.contains(c)) setState(() { _crops.add(c); _cropController.clear(); });
                                },
                              ),
                              if (_crops.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: _crops.map((c) => Chip(
                                    label: Text(c),
                                    onDeleted: () => setState(() => _crops.remove(c)),
                                  )).toList(),
                                ),
                              ],
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: ['en'].contains(_lang) ? _lang : 'en',
                                items: const [
                                  DropdownMenuItem(value: 'en', child: Text('English')),
                                ],
                                onChanged: (v) => setState(() => _lang = v ?? 'en'),
                                decoration: InputDecoration(labelText: I18n.t('language')),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton(
                                      onPressed: _saving ? null : _save,
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Text(_saving ? '...' : I18n.t('save_profile')),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppButton(
                                      onPressed: widget.onClose,
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.darkPrimary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Text(I18n.t('cancel')),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: AppButton(
                        onPressed: _logout,
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.darkPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(I18n.t('logout')),
                      ),
                    )
                  ],
                ),
        ),
      ),
    );
  }
}
