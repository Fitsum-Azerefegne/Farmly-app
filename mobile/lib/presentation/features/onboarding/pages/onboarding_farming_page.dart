import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api.dart';
import '../widgets/onboarding_scaffold.dart';
import '../../chat/pages/chat_page.dart';

const _kUserTypes = [
  {'value': 'aspiring', 'label': 'Aspiring farmer'},
  {'value': 'beginner', 'label': 'Beginner farmer'},
  {'value': 'experienced', 'label': 'Experienced farmer'},
  {'value': 'explorer', 'label': 'Explorer'},
];

const _kGoals = [
  {'value': 'increase_yield', 'label': 'Increase crop yield'},
  {'value': 'reduce_costs', 'label': 'Reduce farming costs'},
  {'value': 'sustainable_farming', 'label': 'Sustainable farming'},
  {'value': 'organic_farming', 'label': 'Organic farming'},
  {'value': 'market_access', 'label': 'Better market access'},
];

const _kYears = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30];

class OnboardingFarmingPage extends StatefulWidget {
  final String accessToken;
  final String fullName;
  final String phoneNumber;
  final String locationString;

  const OnboardingFarmingPage({
    super.key,
    required this.accessToken,
    required this.fullName,
    required this.phoneNumber,
    required this.locationString,
  });

  @override
  State<OnboardingFarmingPage> createState() => _OnboardingFarmingPageState();
}

class _OnboardingFarmingPageState extends State<OnboardingFarmingPage> {
  String? _userType;
  int _years = 0;
  String? _mainGoal;
  final List<String> _crops = [];
  final _cropController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  bool get _isValid =>
      _userType != null && _mainGoal != null && _crops.isNotEmpty;

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
    try {
      final body = jsonEncode({
        'full_name': widget.fullName,
        'phone_number': widget.phoneNumber,
        'location': widget.locationString,
        'user_type': _userType,
        'years_experience': _years,
        'main_goal': _mainGoal,
        'crops_grown': _crops,
      });
      http.Response? lastResp;
      for (final base in apiBases) {
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
      String msg = 'Failed to save profile.';
      if (lastResp != null) {
        try {
          final d = jsonDecode(lastResp.body);
          final detail = d['detail'];
          if (detail is String) {
            msg = detail;
          } else if (detail is List &&
              detail.isNotEmpty &&
              detail.first is Map) {
            msg = detail.first['msg']?.toString() ?? msg;
          }
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _error = msg;
          _isLoading = false;
        });
      }
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
    return OnboardingScaffold(
      step: 3,
      title: 'Your Farming',
      subtitle: 'Help us personalise your recommendations.',
      icon: Icons.agriculture_rounded,
      canContinue: _isValid && !_isLoading,
      onContinue: _submit,
      continueLabel: _isLoading ? 'Saving...' : 'Complete Setup',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Farming Experience'),
          const SizedBox(height: 8),
          _DropdownField<String>(
            value: _userType,
            hint: 'Select experience level',
            items: _kUserTypes
                .map((t) => DropdownMenuItem(
                    value: t['value'], child: Text(t['label']!)))
                .toList(),
            onChanged: (v) => setState(() => _userType = v),
          ),
          const SizedBox(height: 16),
          _label('Years of Experience'),
          const SizedBox(height: 8),
          _DropdownField<int>(
            value: _years,
            hint: 'Select years',
            items: _kYears
                .map((y) => DropdownMenuItem(
                    value: y, child: Text('$y ${y == 1 ? "year" : "years"}')))
                .toList(),
            onChanged: (v) => setState(() => _years = v ?? 0),
          ),
          const SizedBox(height: 16),
          _label('Main Goal'),
          const SizedBox(height: 8),
          _DropdownField<String>(
            value: _mainGoal,
            hint: 'Select your main goal',
            items: _kGoals
                .map((g) => DropdownMenuItem(
                    value: g['value'], child: Text(g['label']!)))
                .toList(),
            onChanged: (v) => setState(() => _mainGoal = v),
          ),
          const SizedBox(height: 16),
          _label('Crops Grown'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cropController,
                  decoration: const InputDecoration(
                      hintText: 'Add at least one crop'),
                  onSubmitted: (_) => _addCrop(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addCrop,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          if (_crops.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _crops
                  .map((c) => Chip(
                        label: Text(c, style: const TextStyle(fontSize: 13)),
                        deleteIcon: const Icon(Icons.close, size: 15),
                        onDeleted: () => setState(() => _crops.remove(c)),
                        backgroundColor: AppColors.backgroundLight,
                        side: const BorderSide(
                            color: Color.fromRGBO(27, 138, 62, 0.3)),
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
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.darkPrimary));
}

class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style:
                  const TextStyle(color: AppColors.mutedLight, fontSize: 14)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary),
          items: items,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.text),
        ),
      ),
    );
  }
}
