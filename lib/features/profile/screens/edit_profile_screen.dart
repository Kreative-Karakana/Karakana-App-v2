import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _biographyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _xController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedGender;
  DateTime? _dateOfBirth;
  File? _pickedAvatar;
  File? _pickedCover;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _firstNameController.text = user?['first_name'] ?? '';
    _lastNameController.text = user?['last_name'] ?? '';
    _biographyController.text = user?['biography'] ?? '';
    _phoneController.text = user?['phone_number'] ?? '';
    _facebookController.text = user?['facebook_username'] ?? '';
    _instagramController.text = user?['instagram_username'] ?? '';
    _xController.text = user?['x_username'] ?? '';
    _linkedinController.text = user?['linkedin_username'] ?? '';
    _selectedGender = user?['gender'] as String?;

    final dobStr = user?['date_of_birth'] as String?;
    if (dobStr != null && dobStr.isNotEmpty) {
      try {
        _dateOfBirth = DateTime.parse(dobStr);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _biographyController.dispose();
    _phoneController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _xController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isAvatar}) async {
    final source = await _showImageSourceSheet();
    if (source == null) return;

    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() {
      if (isAvatar) {
        _pickedAvatar = File(file.path);
      } else {
        _pickedCover = File(file.path);
      }
    });
  }

  Future<ImageSource?> _showImageSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Chagua kutoka Matunzio',
                  style: GoogleFonts.montserrat(fontSize: 15)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text('Piga Picha', style: GoogleFonts.montserrat(fontSize: 15)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Chagua Tarehe ya Kuzaliwa',
      cancelText: 'Ghairi',
      confirmText: 'Thibitisha',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    final threeYearsAgo =
        DateTime.now().subtract(const Duration(days: 3 * 365 + 1));
    if (picked.isAfter(threeYearsAgo)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tarehe ya kuzaliwa lazima iwe zaidi ya miaka 3 iliyopita',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }
    setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // DOB is required if it hasn't been set yet
    final auth = context.read<AuthProvider>();
    final existingDob = auth.user?['date_of_birth'] as String?;
    if ((existingDob == null || existingDob.isEmpty) && _dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tafadhali weka tarehe ya kuzaliwa',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final userId = auth.userId;

    // Step 1: PATCH text fields
    try {
      await ApiClient().dio.patch(
        '${ApiEndpoints.profileDetail}$userId/',
        data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'biography': _biographyController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          if (_selectedGender != null) 'gender': _selectedGender,
          if (_dateOfBirth != null)
            'date_of_birth': DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
          'facebook_username': _facebookController.text.trim(),
          'instagram_username': _instagramController.text.trim(),
          'x_username': _xController.text.trim(),
          'linkedin_username': _linkedinController.text.trim(),
        },
      );
    } catch (e) {
      if (!mounted) return;
      // Check for phone number duplicate
      final parsed = ApiClient().parseError(e);
      final msg =
          parsed.toLowerCase().contains('phone number already exists') ||
                  parsed.toLowerCase().contains('phone_number')
              ? 'Namba ya simu tayari imeshasajiliwa na mtu mwingine'
              : 'Zoezi limeshindikana. Jaribu tena.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.montserrat(color: Colors.white)),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isSaving = false);
      return;
    }

    // Step 2: PATCH images only if new ones were picked
    if (_pickedAvatar != null || _pickedCover != null) {
      try {
        final formData = FormData();
        if (_pickedAvatar != null) {
          formData.files.add(MapEntry(
            'avatar',
            await MultipartFile.fromFile(_pickedAvatar!.path,
                filename: 'avatar.jpg'),
          ));
        }
        if (_pickedCover != null) {
          formData.files.add(MapEntry(
            'cover',
            await MultipartFile.fromFile(_pickedCover!.path,
                filename: 'cover.jpg'),
          ));
        }
        await ApiClient().dio.patch(
          '${ApiEndpoints.profileDetail}$userId/',
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
          ),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maelezo yamehifadhiwa lakini picha hazikupakiwa. Jaribu tena.',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    }

    if (!mounted) return;
    await auth.initialize();
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Wasifu umesasishwa kikamilifu!',
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE87722),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isTrainer = auth.isTrainer;
    final existingAvatar = auth.userAvatar;
    final existingCover = auth.user?['cover'] as String?;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Hariri Wasifu',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Hifadhi',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cover + Avatar header ──────────────────────────────
              _CoverAvatarHeader(
                pickedAvatar: _pickedAvatar,
                pickedCover: _pickedCover,
                existingAvatar: existingAvatar,
                existingCover: existingCover,
                userName: auth.userFullName,
                onTapAvatar: () => _pickImage(isAvatar: true),
                onTapCover: () => _pickImage(isAvatar: false),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Basic Info ────────────────────────────────────
                    _sectionLabel('Taarifa za Msingi'),
                    const SizedBox(height: 12),
                    _buildField('Jina la Kwanza', _firstNameController,
                        Icons.person_outline,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Weka jina la kwanza' : null),
                    const SizedBox(height: 12),
                    _buildField('Jina la Familia', _lastNameController,
                        Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildField('Maelezo Mafupi', _biographyController,
                        Icons.info_outline,
                        maxLines: 3),
                    const SizedBox(height: 12),
                    _buildField('Nambari ya Simu', _phoneController,
                        Icons.phone_outlined,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),

                    // Gender dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: _inputDecoration('Jinsia', Icons.people_outline),
                      items: const [
                        DropdownMenuItem(value: 'M', child: Text('Mwanaume')),
                        DropdownMenuItem(value: 'F', child: Text('Mwanamke')),
                        DropdownMenuItem(value: 'O', child: Text('Nyingine')),
                      ],
                      onChanged: (v) => setState(() => _selectedGender = v),
                    ),
                    const SizedBox(height: 12),

                    // Date of Birth
                    GestureDetector(
                      onTap: _pickDateOfBirth,
                      child: AbsorbPointer(
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: _dateOfBirth != null
                                ? DateFormat('dd MMM yyyy').format(_dateOfBirth!)
                                : '',
                          ),
                          decoration: _inputDecoration(
                            'Tarehe ya Kuzaliwa',
                            Icons.cake_outlined,
                          ).copyWith(
                            hintText: 'Bonyeza kuchagua tarehe',
                            hintStyle: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                            suffixIcon: const Icon(Icons.calendar_today_outlined,
                                size: 18, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),

                    // ── Social Media (trainers only) ──────────────────
                    if (isTrainer) ...[
                      const SizedBox(height: 28),
                      _sectionLabel('Mitandao ya Kijamii'),
                      const SizedBox(height: 12),
                      _buildField(
                        'Facebook',
                        _facebookController,
                        Icons.facebook,
                        iconColor: const Color(0xFF1877F2),
                        hint: 'https://facebook.com/jina-lako',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        'Instagram',
                        _instagramController,
                        Icons.camera_alt_outlined,
                        iconColor: const Color(0xFFE1306C),
                        hint: 'https://instagram.com/jina-lako',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        'X (Twitter)',
                        _xController,
                        Icons.alternate_email,
                        iconColor: Colors.black,
                        hint: 'https://twitter.com/jina-lako',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        'LinkedIn',
                        _linkedinController,
                        Icons.work_outline,
                        iconColor: const Color(0xFF0077B5),
                        hint: 'https://linkedin.com/in/jina-lako',
                        keyboardType: TextInputType.url,
                      ),
                    ],

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Hifadhi Mabadiliko',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {Color? iconColor}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      filled: true,
      fillColor: Theme.of(context).cardColor,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    Color? iconColor,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textPrimary),
      decoration: _inputDecoration(label, icon, iconColor: iconColor).copyWith(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey.shade400),
      ),
    );
  }
}

// ── Cover + Avatar header widget ──────────────────────────────────────────────

class _CoverAvatarHeader extends StatelessWidget {
  final File? pickedAvatar;
  final File? pickedCover;
  final String? existingAvatar;
  final String? existingCover;
  final String userName;
  final VoidCallback onTapAvatar;
  final VoidCallback onTapCover;

  const _CoverAvatarHeader({
    required this.pickedAvatar,
    required this.pickedCover,
    required this.existingAvatar,
    required this.existingCover,
    required this.userName,
    required this.onTapAvatar,
    required this.onTapCover,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover image
          GestureDetector(
            onTap: onTapCover,
            child: Container(
              width: double.infinity,
              height: 155,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (pickedCover != null)
                    Image.file(pickedCover!, fit: BoxFit.cover)
                  else if (existingCover != null && existingCover!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: existingCover!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox(),
                    ),
                  // Overlay hint
                  Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    child: const Center(
                      child: Icon(Icons.photo_camera,
                          color: Colors.white, size: 36),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Avatar circle
          Positioned(
            bottom: 0,
            left: 20,
            child: GestureDetector(
              onTap: onTapAvatar,
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      color: AppColors.primary,
                    ),
                    child: ClipOval(
                      child: pickedAvatar != null
                          ? Image.file(pickedAvatar!, fit: BoxFit.cover)
                          : existingAvatar != null
                              ? CachedNetworkImage(
                                  imageUrl: existingAvatar!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      _avatarFallback(userName),
                                )
                              : _avatarFallback(userName),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'K',
          style: GoogleFonts.montserrat(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
