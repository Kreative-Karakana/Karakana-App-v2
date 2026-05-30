import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/top_popup.dart';

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
      final data = _extractList(response.data);
      if (!mounted) return;
      setState(() {
        _regions = data
            .map((e) => _Region(
                  code:
                      _asInt(_mapValue(e, const ['region_code', 'code', 'id'])),
                  name: _asString(_mapValue(e, const ['region_name', 'name'])),
                ))
            .where((r) => r.code != 0 && r.name.isNotEmpty)
            .toList();
        _loadingRegions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRegions = false);
    }
  }

  Future<void> _loadDistricts(int regionCode) async {
    if (!mounted) return;
    setState(() {
      _loadingDistricts = true;
      _districts = [];
      _selectedDistrictCode = null;
    });
    try {
      final response = await ApiClient().dio.get(
            'https://api.locations.co.tz/v1/regions/$regionCode/districts/?limit=50',
          );
      final data = _extractList(response.data);
      if (!mounted) return;
      setState(() {
        _districts = data
            .map((e) => _District(
                  code: _asInt(
                      _mapValue(e, const ['district_code', 'code', 'id'])),
                  name:
                      _asString(_mapValue(e, const ['district_name', 'name'])),
                ))
            .where((d) => d.code != 0 && d.name.isNotEmpty)
            .toList();
        _loadingDistricts = false;
      });
    } catch (_) {
      if (!mounted) return;
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
      _snack('Asante kwa kushiriki, taarifa zimehifadhiwa', success: true);

      if (widget.shouldPop) {
        context.pop();
      } else {
        context.go('/trainer/apply');
      }
    } catch (e) {
      if (!mounted) return;
      final statusCode = e is DioException ? e.response?.statusCode : null;
      if (statusCode == 404) {
        _snack('Taarifa zako sio sahihi, tafadhali hakiki taarifa zako');
      } else {
        _snack('Kuna hitilafu imetokea. Jaribu tena.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String message, {bool success = false}) {
    showTopPopup(
      context,
      message,
      isError: !success,
      duration: const Duration(milliseconds: 4000),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Fomu ya Taarifa',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg - AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.lg - AppSpacing.xs,
            AppSpacing.xl + AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maboresho ya wasifu wa mtumiaji',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),

            // Info banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md - AppSpacing.xs / 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius:
                    BorderRadius.circular(AppSpacing.sm + AppSpacing.xs),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs / 2),
                  Expanded(
                    child: Text(
                      'Maelezo yako ni ya siri na yatatumika kwa madhumuni ya takwimu tu, ili tuweze kuboresha huduma zetu.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tafadhali jaza maelezo yote kwa ukamilifu',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: AppSpacing.xl - AppSpacing.xs),

            // ── Location type ─────────────────────────────────────
            _sectionLabel('Aina ya makao yako'),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _locationType,
              decoration: _inputDecoration(
                  'Chagua aina ya eneo', Icons.location_city_outlined),
              items: _locationTypes
                  .map((o) => DropdownMenuItem(
                      value: o.value,
                      child: Text(o.label, style: GoogleFonts.montserrat())))
                  .toList(),
              onChanged: (v) => setState(() => _locationType = v),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Region ────────────────────────────────────────────
            _sectionLabel('Mkoa'),
            const SizedBox(height: AppSpacing.sm),
            if (_loadingRegions)
              const Center(child: KarakanaWaveLoader(color: AppColors.primary))
            else
              DropdownButtonFormField<int>(
                initialValue: _selectedRegionCode,
                decoration:
                    _inputDecoration('Chagua jina la mkoa', Icons.map_outlined),
                items: _regions
                    .map((r) => DropdownMenuItem(
                        value: r.code,
                        child: Text(r.name, style: GoogleFonts.montserrat())))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedRegionCode = v;
                  });
                  if (v != null) _loadDistricts(v);
                },
              ),
            const SizedBox(height: AppSpacing.lg),

            // ── District ──────────────────────────────────────────
            _sectionLabel('Wilaya'),
            const SizedBox(height: AppSpacing.sm),
            if (_selectedRegionCode == null)
              Text(
                'Chagua mkoa kwanza',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: Colors.grey.shade400),
              )
            else if (_loadingDistricts)
              const Center(child: KarakanaWaveLoader(color: AppColors.primary))
            else
              DropdownButtonFormField<int>(
                initialValue: _selectedDistrictCode,
                decoration: _inputDecoration(
                    'Chagua jina la wilaya', Icons.location_on_outlined),
                items: _districts
                    .map((d) => DropdownMenuItem(
                        value: d.code,
                        child: Text(d.name, style: GoogleFonts.montserrat())))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDistrictCode = v),
              ),
            const SizedBox(height: AppSpacing.lg),

            // ── Education level ───────────────────────────────────
            _sectionLabel('Kiwango cha Elimu'),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _educationLevel,
              decoration: _inputDecoration(
                  'Chagua kiwango chako cha elimu', Icons.school_outlined),
              items: _educationLevels
                  .map((o) => DropdownMenuItem(
                        value: o.value,
                        child: Text(o.label, style: AppTextStyles.bodyMedium),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _educationLevel = v),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Switches ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: const Color(0xFFE8D5C8)),
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
            const SizedBox(height: AppSpacing.xl + AppSpacing.xs),

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
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: KarakanaWaveLoader(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Wasilisha Fomu',
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
      );

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );

  Widget _buildSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md - AppSpacing.xs / 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  List<dynamic> _extractList(dynamic source) {
    if (source is List) return source;
    if (source is Map<String, dynamic>) {
      final directData = source['data'];
      if (directData is List) return directData;
      final results = source['results'];
      if (results is List) return results;
      final items = source['items'];
      if (items is List) return items;
    }
    return const [];
  }

  dynamic _mapValue(dynamic source, List<String> keys) {
    if (source is! Map) return null;
    for (final key in keys) {
      if (source.containsKey(key)) return source[key];
    }
    return null;
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
