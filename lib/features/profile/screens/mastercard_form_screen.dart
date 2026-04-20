import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

class MastercardFormScreen extends StatefulWidget {
  /// When true, pops on success instead of continuing to trainer application.
  final bool shouldPop;

  const MastercardFormScreen({super.key, this.shouldPop = false});

  @override
  State<MastercardFormScreen> createState() => _MastercardFormScreenState();
}

class _MastercardFormScreenState extends State<MastercardFormScreen> {
  String? _locationType;
  int? _selectedRegionCode;
  String? _selectedRegionName;
  int? _selectedDistrictCode;
  String? _educationLevel;
  bool _isDisabled = false;
  bool _isRefugee = false;
  bool _isSaving = false;

  // Loaded from external API
  List<_Region> _regions = [];
  List<_District> _districts = [];
  bool _loadingRegions = true;
  bool _loadingDistricts = false;

  final _locationTypes = const [
    _Option('URB', 'Mjini'),
    _Option('RUR', 'Vijijini'),
  ];

  final _educationLevels = const [
    _Option('ECD', 'Elimu ya ukuaji na malezi ya awali'),
    _Option('PRM', 'Elimu ya msingi'),
    _Option('SEC', 'Elimu ya sekondari'),
    _Option('TER', 'Elimu ya ufundi'),
    _Option('PRO', 'Elimu ya juu'),
  ];

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    try {
      final response = await ApiClient().dio.get(
        'https://api.locations.co.tz/v1/regions/?limit=30',
        options: null,
      );
      final data = response.data['data'] as List? ?? [];
      setState(() {
        _regions = data
            .map((e) => _Region(
                  code: e['region_code'] as int? ?? 0,
                  name: e['region_name'] as String? ?? '',
                ))
            .where((r) => r.code != 0 && r.name.isNotEmpty)
            .toList();
        _loadingRegions = false;
      });
    } catch (_) {
      setState(() => _loadingRegions = false);
    }
  }

  Future<void> _loadDistricts(int regionCode) async {
    setState(() {
      _loadingDistricts = true;
      _districts = [];
      _selectedDistrictCode = null;
    });
    try {
      final response = await ApiClient().dio.get(
        'https://api.locations.co.tz/v1/regions/$regionCode/districts/?limit=50',
      );
      final data = response.data['data'] as List? ?? [];
      setState(() {
        _districts = data
            .map((e) => _District(
                  code: e['district_code'] as int? ?? 0,
                  name: e['district_name'] as String? ?? '',
                ))
            .where((d) => d.code != 0 && d.name.isNotEmpty)
            .toList();
        _loadingDistricts = false;
      });
    } catch (_) {
      setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _submit() async {
    if (_locationType == null) {
      _snack('Tafadhali chagua aina ya makao yako');
      return;
    }
    if (_selectedRegionCode == null) {
      _snack('Tafadhali chagua mkoa wako');
      return;
    }
    if (_selectedDistrictCode == null) {
      _snack('Tafadhali chagua wilaya yako');
      return;
    }
    if (_educationLevel == null) {
      _snack('Tafadhali chagua kiwango chako cha elimu');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ApiClient().dio.post(
        ApiEndpoints.masterCard,
        data: {
          'location_type': _locationType,
          // Note: typo preserved from backend API spec
          'eductation_level': _educationLevel,
          'is_disabled': _isDisabled,
          'is_refugee': _isRefugee,
          'district_code': _selectedDistrictCode,
        },
      );

      if (!mounted) return;
      _snack('Asante kwa kushiriki, taarifa zimehifadhiwa',
          success: true);

      if (widget.shouldPop) {
        context.pop();
      } else {
        context.go('/trainer/apply');
      }
    } catch (e) {
      if (!mounted) return;
      final parsed = ApiClient().parseError(e);
      if (parsed.contains('404') || parsed.contains('not found')) {
        _snack('Taarifa zako sio sahihi, tafadhali hakiki taarifa zako');
      } else {
        _snack('Kuna hitilafu imetokea. Jaribu tena.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: success ? const Color(0xFF2E7D32) : AppColors.primary,
        duration: const Duration(milliseconds: 4000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Fomu ya Taarifa',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maboresho ya wasifu wa mtumiaji',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Info banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Maelezo yako ni ya siri na yatatumika kwa madhumuni ya takwimu tu, ili tuweze kuboresha huduma zetu.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tafadhali jaza maelezo yote kwa ukamilifu',
              style: GoogleFonts.inter(
                  fontSize: 13.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 28),

            // ── Location type ─────────────────────────────────────
            _sectionLabel('Aina ya makao yako'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _locationType,
              decoration: _inputDecoration('Chagua aina ya eneo',
                  Icons.location_city_outlined),
              items: _locationTypes
                  .map((o) => DropdownMenuItem(
                      value: o.value,
                      child: Text(o.label, style: GoogleFonts.inter())))
                  .toList(),
              onChanged: (v) => setState(() => _locationType = v),
            ),
            const SizedBox(height: 20),

            // ── Region ────────────────────────────────────────────
            _sectionLabel('Mkoa'),
            const SizedBox(height: 8),
            if (_loadingRegions)
              const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
            else
              DropdownButtonFormField<int>(
                value: _selectedRegionCode,
                decoration:
                    _inputDecoration('Chagua jina la mkoa', Icons.map_outlined),
                items: _regions
                    .map((r) => DropdownMenuItem(
                        value: r.code,
                        child: Text(r.name, style: GoogleFonts.inter())))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedRegionCode = v;
                    _selectedRegionName =
                        _regions.firstWhere((r) => r.code == v).name;
                  });
                  if (v != null) _loadDistricts(v);
                },
              ),
            const SizedBox(height: 20),

            // ── District ──────────────────────────────────────────
            _sectionLabel('Wilaya'),
            const SizedBox(height: 8),
            if (_selectedRegionCode == null)
              Text(
                'Chagua mkoa kwanza',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.grey.shade400),
              )
            else if (_loadingDistricts)
              const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
            else
              DropdownButtonFormField<int>(
                value: _selectedDistrictCode,
                decoration: _inputDecoration(
                    'Chagua jina la wilaya', Icons.location_on_outlined),
                items: _districts
                    .map((d) => DropdownMenuItem(
                        value: d.code,
                        child: Text(d.name, style: GoogleFonts.inter())))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDistrictCode = v),
              ),
            const SizedBox(height: 20),

            // ── Education level ───────────────────────────────────
            _sectionLabel('Kiwango cha Elimu'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _educationLevel,
              decoration:
                  _inputDecoration('Chagua kiwango chako cha elimu',
                      Icons.school_outlined),
              items: _educationLevels
                  .map((o) => DropdownMenuItem(
                        value: o.value,
                        child: Text(o.label,
                            style: GoogleFonts.inter(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _educationLevel = v),
            ),
            const SizedBox(height: 20),

            // ── Switches ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: const Color(0xFFE8D5C8)),
              ),
              child: Column(
                children: [
                  _buildSwitch(
                    label: 'Je, una ulemavu wowote?',
                    value: _isDisabled,
                    onChanged: (v) => setState(() => _isDisabled = v),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _buildSwitch(
                    label: 'Je, wewe ni mkimbizi?',
                    value: _isRefugee,
                    onChanged: (v) => setState(() => _isRefugee = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // ── Submit button ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Wasilisha Fomu',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 13.5, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );

  Widget _buildSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _Option {
  final String value;
  final String label;
  const _Option(this.value, this.label);
}

class _Region {
  final int code;
  final String name;
  const _Region({required this.code, required this.name});
}

class _District {
  final int code;
  final String name;
  const _District({required this.code, required this.name});
}
