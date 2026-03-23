import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _dobCtrl;

  String? _selectedGender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user ?? {};
    _firstNameCtrl = TextEditingController(
      text: user['first_name']?.toString() ?? '',
    );
    _lastNameCtrl = TextEditingController(
      text: user['last_name']?.toString() ?? '',
    );
    _bioCtrl = TextEditingController(
      text: user['bio']?.toString() ?? '',
    );
    _phoneCtrl = TextEditingController(
      text: user['phone']?.toString() ?? '',
    );
    _dobCtrl = TextEditingController(
      text: user['date_of_birth']?.toString() ?? '',
    );
    _selectedGender = user['gender']?.toString();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final dio = ApiClient.instance.dio;
      final fields = <String, dynamic>{};
      if (_firstNameCtrl.text.trim().isNotEmpty) {
        fields['first_name'] = _firstNameCtrl.text.trim();
      }
      if (_lastNameCtrl.text.trim().isNotEmpty) {
        fields['last_name'] = _lastNameCtrl.text.trim();
      }
      if (_bioCtrl.text.trim().isNotEmpty) {
        fields['biography'] = _bioCtrl.text.trim();
      }
      if (_phoneCtrl.text.trim().isNotEmpty) {
        fields['phone_number'] = _phoneCtrl.text.trim();
      }
      if (_selectedGender != null) {
        fields['gender'] = _selectedGender;
      }
      if (_dobCtrl.text.trim().isNotEmpty) {
        fields['date_of_birth'] = _dobCtrl.text.trim();
      }
      final response = await dio.patch('/api/v1/profiles/me/', data: fields);

      if (mounted) {
        // Refresh user data in provider.
        final auth = context.read<AuthProvider>();
        final updated = Map<String, dynamic>.from(auth.user ?? {});
        updated.addAll(response.data as Map<String, dynamic>);
        // Trigger a re-fetch to sync the provider.
        await auth.initialize();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ──────────────────────────────
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.lightOrange,
                      backgroundImage:
                          auth.userAvatar != null &&
                              auth.userAvatar!.isNotEmpty
                          ? CachedNetworkImageProvider(auth.userAvatar!)
                          : null,
                      child:
                          (auth.userAvatar == null || auth.userAvatar!.isEmpty)
                          ? Icon(
                              Icons.person,
                              size: 36,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Image upload coming soon'),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Fields ──────────────────────────────
              _fieldLabel('First Name'),
              const SizedBox(height: 6),
              _buildField(
                controller: _firstNameCtrl,
                hint: 'Enter first name',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _fieldLabel('Last Name'),
              const SizedBox(height: 6),
              _buildField(
                controller: _lastNameCtrl,
                hint: 'Enter last name',
              ),
              const SizedBox(height: 16),

              _fieldLabel('Biography'),
              const SizedBox(height: 6),
              _buildField(
                controller: _bioCtrl,
                hint: 'Tell us about yourself...',
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              _fieldLabel('Phone Number'),
              const SizedBox(height: 6),
              _buildField(
                controller: _phoneCtrl,
                hint: '+255 700 000 000',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _fieldLabel('Gender'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: _fieldDecoration('Select gender'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
              const SizedBox(height: 16),

              _fieldLabel('Date of Birth'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _dobCtrl,
                readOnly: true,
                decoration: _fieldDecoration('YYYY-MM-DD').copyWith(
                  suffixIcon: Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.grey,
                    size: 18,
                  ),
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 32),

              // ── Save button ─────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.dark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.dark,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.grey, fontSize: 14),
      filled: true,
      fillColor: AppColors.lightOrange,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppColors.dark, fontSize: 14),
      decoration: _fieldDecoration(hint),
    );
  }
}
