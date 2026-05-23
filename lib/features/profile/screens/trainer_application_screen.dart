import 'dart:io';

import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_selector/file_selector.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/top_popup.dart';

class TrainerApplicationScreen extends StatefulWidget {
  const TrainerApplicationScreen({super.key});

  @override
  State<TrainerApplicationScreen> createState() =>
      _TrainerApplicationScreenState();
}

class _TrainerApplicationScreenState extends State<TrainerApplicationScreen> {
  Map<String, dynamic>? _existingApplication;
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  bool _isSubmitting = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _whyController = TextEditingController();
  final TextEditingController _topicsController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  File? _cvFile;
  String? _cvFileName;
  bool _isPickingFile = false;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _whyController.dispose();
    _topicsController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  bool get _isProfileComplete {
    final p = _profileData;
    if (p == null) return false;
    final hasFirstName = (p['first_name'] as String? ?? '').isNotEmpty;
    final hasLastName = (p['last_name'] as String? ?? '').isNotEmpty;
    final hasGender = (p['gender'] as String? ?? '').isNotEmpty;
    final hasAvatar = (p['avatar'] as String? ?? '').isNotEmpty;
    final hasPhone = (p['phone_number'] as String? ?? '').isNotEmpty;
    final hasDob = (p['date_of_birth'] as String? ?? '').isNotEmpty;
    return hasFirstName &&
        hasLastName &&
        hasGender &&
        hasAvatar &&
        hasPhone &&
        hasDob;
  }

  Future<void> _loadApplication() async {
    try {
      final results = await Future.wait([
        ApiClient().dio.get('/api/v1/trainer-application/'),
        ApiClient().dio.get('/api/v1/profiles/me/'),
      ]);
      final appData = results[0].data;
      final appList = appData is Map
          ? (appData['results'] as List? ?? [])
          : (appData as List? ?? []);
      if (!mounted) return;
      setState(() {
        _existingApplication = appList.isNotEmpty
            ? Map<String, dynamic>.from(appList.first as Map)
            : null;
        _profileData = Map<String, dynamic>.from(results[1].data as Map? ?? {});
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCV() async {
    setState(() => _isPickingFile = true);
    try {
      const typeGroup = XTypeGroup(
        label: 'PDF',
        extensions: ['pdf'],
        mimeTypes: ['application/pdf'],
      );
      final picked = await openFile(acceptedTypeGroups: [typeGroup]);
      if (picked != null && picked.path.isNotEmpty) {
        final fileName = picked.name.toLowerCase();
        if (!fileName.endsWith('.pdf')) {
          if (!mounted) return;
          showTopPopup(context, 'Tafadhali pakia faili la PDF pekee.');
          return;
        }
        setState(() {
          _cvFile = File(picked.path);
          _cvFileName = picked.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      showTopPopup(context, 'Hitilafu ya kuchagua faili. Jaribu tena.');
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cvFile == null) {
      showTopPopup(
          context, 'Inashauriwa kupakia CV yako ili ombi lako likubalike.');
      await _submitWithoutCV();
      return;
    }
    await _doSubmit();
  }

  Future<void> _submitWithoutCV() async => _doSubmit();

  Future<void> _doSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      await ApiClient().dio.post(
        '/api/v1/trainer-application/',
        data: {
          'professional_title': _titleController.text,
          'professional_bio': _bioController.text,
          'teaching_experience': _experienceController.text,
          'why_do_you_want_to_teach': _whyController.text,
          'topics_of_interest': _topicsController.text,
          'country': _countryController.text,
        },
      );
      if (!mounted) return;
      showTopPopup(context, 'Ombi limetumwa! Tutakujibu hivi karibuni.',
          isError: false);
      context.pop();
    } catch (_) {
      if (!mounted) return;
      showTopPopup(context, 'Hitilafu. Jaribu tena.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Omba Kuwa Mkufunzi',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: KarakanaWaveLoader(color: Color(0xFFE87722)),
                )
              : SingleChildScrollView(
                  padding: AppSpacing.sectionPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: AppSpacing.sectionPadding,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1A0A00),
                              Color(0xFF3D1800),
                              Color(0xFF7B3A10)
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kuwa Mkufunzi Karakana',
                                    style: AppTextStyles.h3.copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Shiriki ujuzi wako na upate kipato kwa kufundisha wengine.',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.school,
                              color: Colors.white.withValues(alpha: 0.3),
                              size: 56,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl - AppSpacing.xs),
                      if (_profileData != null && !_isProfileComplete)
                        _buildProfileGate()
                      else if (_existingApplication != null)
                        _buildStatusCard(_existingApplication!)
                      else
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildField(
                                'Cheo cha Kitaaluma',
                                _titleController,
                                hint: 'Mfano: Mjasiriamali, Mhasibu, Meneja',
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Weka cheo chako'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                'Wasifu wa Kitaaluma',
                                _bioController,
                                hint: 'Elezea ujuzi wako na uzoefu...',
                                maxLines: 4,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Weka wasifu wako'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                'Uzoefu wa Kufundisha',
                                _experienceController,
                                hint: 'Je, umewahi kufundisha kabla? Elezea...',
                                maxLines: 3,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                'Kwa Nini Unataka Kufundisha?',
                                _whyController,
                                hint: 'Shiriki sababu yako...',
                                maxLines: 3,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Weka sababu yako'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                'Mada za Kufundisha',
                                _topicsController,
                                hint: 'Mfano: Ujasiriamali, Fedha, Uongozi',
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Weka mada zako'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                'Nchi Unayoishi *',
                                _countryController,
                                hint: 'Mfano: Tanzania, Kenya, Uganda',
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Weka nchi unayoishi'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'CV / Portfolio',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Pakia CV yako kwa PDF ili tuweze kukutathmini vizuri zaidi.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              GestureDetector(
                                onTap: _isPickingFile ? null : _pickCV,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: AppSpacing.cardPadding,
                                  decoration: BoxDecoration(
                                    color: _cvFile != null
                                        ? AppColors.successLight
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(AppRadius.input),
                                    border: Border.all(
                                      color: _cvFile != null
                                          ? AppColors.success
                                          : AppColors.inputBorder,
                                      width: _cvFile != null ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _cvFile != null
                                              ? AppColors.success
                                                  .withValues(alpha: 0.1)
                                              : AppColors.primaryLight,
                                          borderRadius:
                                              BorderRadius.circular(AppSpacing.sm + AppSpacing.xs),
                                        ),
                                        child: _isPickingFile
                                            ? const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: KarakanaWaveLoader(
                                                    strokeWidth: 2,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              )
                                            : Icon(
                                                _cvFile != null
                                                    ? Icons.check_circle_outline
                                                    : Icons
                                                        .upload_file_outlined,
                                                color: _cvFile != null
                                                    ? AppColors.success
                                                    : AppColors.primary,
                                                size: 24,
                                              ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _cvFile != null
                                                  ? (_cvFileName ??
                                                      'Faili limechaguliwa')
                                                  : 'Pakia CV / Portfolio',
                                              style: GoogleFonts.inter(
                                                fontSize: AppTextStyles.bodyMedium.fontSize,
                                                fontWeight: FontWeight.w600,
                                                color: _cvFile != null
                                                    ? AppColors.success
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: AppSpacing.xs / 2),
                                            Text(
                                              _cvFile != null
                                                  ? 'Bonyeza kubadilisha faili'
                                                  : 'PDF pekee (max 5MB)',
                                              style: GoogleFonts.inter(
                                                fontSize: AppTextStyles.caption.fontSize,
                                                color: AppColors.textTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_cvFile != null)
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            _cvFile = null;
                                            _cvFileName = null;
                                          }),
                                          child: const Icon(
                                            Icons.close,
                                            color: AppColors.textTertiary,
                                            size: 18,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl - AppSpacing.xs),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE87722),
                                    foregroundColor: Colors.white,
                                    minimumSize:
                                        const Size(double.infinity, 54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.button),
                                    ),
                                  ),
                                  onPressed:
                                      _isSubmitting ? null : _submitApplication,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: KarakanaWaveLoader(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Tuma Ombi',
                                          style: AppTextStyles.buttonLarge.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
                    ],
                  ),
                )),
    );
  }

  Widget _buildProfileGate() {
    final p = _profileData!;
    final checks = [
      (
        'Jina la kwanza na la familia',
        (p['first_name'] as String? ?? '').isNotEmpty &&
            (p['last_name'] as String? ?? '').isNotEmpty
      ),
      ('Jinsia', (p['gender'] as String? ?? '').isNotEmpty),
      ('Picha ya wasifu', (p['avatar'] as String? ?? '').isNotEmpty),
      ('Namba ya simu', (p['phone_number'] as String? ?? '').isNotEmpty),
      ('Tarehe ya kuzaliwa', (p['date_of_birth'] as String? ?? '').isNotEmpty),
    ];
    return Container(
      padding: AppSpacing.sectionPadding,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E6),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border:
            Border.all(color: const Color(0xFFE87722).withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.info_outline, color: Color(0xFFE87722), size: 20),
          const SizedBox(width: 8),
          Text('Kamili Wasifu Wako Kwanza',
              style: GoogleFonts.montserrat(
                  fontSize: AppTextStyles.h4.fontSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3D1800))),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(
            'Kabla ya kuomba kuwa Mkufunzi, hakikisha wasifu wako umekamilika:',
            style: GoogleFonts.montserrat(
                fontSize: AppTextStyles.bodyMedium.fontSize, color: const Color(0xFF7B3A10), height: 1.4)),
        const SizedBox(height: AppSpacing.md),
        ...checks.map((check) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs / 2),
              child: Row(children: [
                Icon(
                  check.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: check.$2
                      ? const Color(0xFFE87722)
                      : const Color(0xFFBDA99C),
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs / 2),
                Text(check.$1,
                    style: GoogleFonts.montserrat(
                        fontSize: AppTextStyles.bodyMedium.fontSize,
                        fontWeight:
                            check.$2 ? FontWeight.w500 : FontWeight.w400,
                        color: check.$2
                            ? const Color(0xFF3D1800)
                            : const Color(0xFF9E8070))),
              ]),
            )),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text('Kamili Wasifu Wako',
                style: GoogleFonts.montserrat(
                    fontSize: AppTextStyles.buttonMedium.fontSize, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE87722),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button))),
          ),
        ),
      ]),
    );
  }

  Widget _buildStatusCard(Map application) {
    final status = application['status'] as String? ?? 'pending';
    final color = status == 'approved'
        ? const Color(0xFFE87722)
        : status == 'rejected'
            ? const Color(0xFFB71C1C)
            : const Color(0xFFE87722);
    final icon = status == 'approved'
        ? Icons.check_circle_outline
        : status == 'rejected'
            ? Icons.cancel_outlined
            : Icons.hourglass_empty;
    final title = status == 'approved'
        ? 'Ombi Limekubaliwa!'
        : status == 'rejected'
            ? 'Ombi Limekataliwa'
            : 'Ombi Linasubiriwa';
    final message = status == 'approved'
        ? 'Hongera! Sasa unaweza kuunda na kuchapisha kozi.'
        : status == 'rejected'
            ? 'Samahani. Ombi lako halikukubaliwa wakati huu.'
            : 'Ombi lako lipo kwenye uhakiki. Tutakujibu hivi karibuni.';

    return Container(
      padding: AppSpacing.sectionPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: AppTextStyles.h3.fontSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D1800),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: AppTextStyles.bodyMedium.fontSize,
              color: const Color(0xFF9E8070),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(
            color: Color(0xFFE87722),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(
            color: Color(0xFFB71C1C),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
