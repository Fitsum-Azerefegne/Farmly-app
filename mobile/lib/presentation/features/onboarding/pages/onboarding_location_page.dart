import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import '../widgets/onboarding_scaffold.dart';
import 'onboarding_language_page.dart';

class OnboardingLocationPage extends StatefulWidget {
  final String accessToken;
  final String fullName;
  final String phoneNumber;
  const OnboardingLocationPage({
    super.key,
    required this.accessToken,
    required this.fullName,
    required this.phoneNumber,
  });

  @override
  State<OnboardingLocationPage> createState() => _OnboardingLocationPageState();
}

class _OnboardingLocationPageState extends State<OnboardingLocationPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  String? _selectedAddress;
  String? _selectedCoords; // "lat,lng"
  String? _error;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(
          'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=5');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      final data = jsonDecode(resp.body);
      final features = (data['features'] as List?) ?? [];
      setState(() {
        _results = features.map<Map<String, dynamic>>((f) {
          final props = f['properties'] as Map<String, dynamic>;
          final coords = f['geometry']['coordinates'] as List;
          return {
            'name': props['name'] ?? '',
            'country': props['country'] ?? '',
            'lat': coords[1] as double,
            'lng': coords[0] as double,
          };
        }).toList();
      });
    } catch (_) {
      setState(() => _error = 'Search failed. Check your connection.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectLocation(Map<String, dynamic> item) {
    final lat = item['lat'] as double;
    final lng = item['lng'] as double;
    setState(() {
      _selectedCoords = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
      _selectedAddress = '${item['name']}, ${item['country']}'
          .trim()
          .replaceAll(RegExp(r'^,\s*|,\s*$'), '');
      _results = [];
      _searchController.text = _selectedAddress!;
    });
  }

  void _continue() {
    if (_selectedCoords == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingLanguagePage(
          accessToken: widget.accessToken,
          fullName: widget.fullName,
          phoneNumber: widget.phoneNumber,
          locationString: _selectedCoords!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 1,
      title: 'Your Location',
      subtitle: 'We use this to give you local farming recommendations.',
      icon: Icons.location_on_rounded,
      canContinue: _selectedCoords != null,
      onContinue: _continue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search city or area (e.g. Addis Ababa)',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _results = [];
                              _selectedCoords = null;
                              _selectedAddress = null;
                            });
                          },
                        )
                      : null,
            ),
            onChanged: (v) {
              if (_selectedCoords != null) {
                setState(() => _selectedCoords = null);
              }
              _search(v);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: const [
                  BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: Column(
                children: _results.map((item) {
                  return InkWell(
                    onTap: () => _selectLocation(item),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'] as String,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                if ((item['country'] as String).isNotEmpty)
                                  Text(item['country'] as String,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (_selectedCoords != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color.fromRGBO(27, 138, 62, 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedAddress ?? _selectedCoords!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.darkPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
