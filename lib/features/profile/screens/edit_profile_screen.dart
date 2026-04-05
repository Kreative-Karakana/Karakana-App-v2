import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _biographyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedGender;
  bool _isSaving = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _firstNameController.text = auth.user?['first_name'] ?? '';
    _lastNameController.text = auth.user?['last_name'] ?? '';
    _biographyController.text = auth.user?['biography'] ?? '';
    _phoneController.text = auth.user?['phone_number'] ?? '';
    _selectedGender = auth.user?['gender'] as String?;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _biographyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      await ApiClient().dio.patch(
        '/api/v1/profiles/$userId/',
        data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'biography': _biographyController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          if (_selectedGender != null) 'gender': _selectedGender,
        },
      );
      await authProvider.initialize();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wasifu umesasishwa kikamilifu!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hitilafu. Jaribu tena.'),
          backgroundColor: Color(0xFFB71C1C),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B1A08),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Hariri Wasifu',
          style: GoogleFonts.poppins(
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
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Hifadhi',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    Consumer<AuthProvider>(
                      builder: (_, auth, __) => Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFC4620A),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: auth.userAvatar != null
                              ? CachedNetworkImage(
                                  imageUrl: auth.userAvatar!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => _avatarFallback(auth),
                                )
                              : _avatarFallback(auth),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC4620A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildField(
                'Jina la Kwanza',
                _firstNameController,
                Icons.person_outline,
                validator: (v) => v == null || v.isEmpty
                    ? 'Weka jina la kwanza'
                    : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                'Jina la Familia',
                _lastNameController,
                Icons.person_outline,
              ),
              const SizedBox(height: 14),
              _buildField(
                'Maelezo Mafupi',
                _biographyController,
                Icons.info_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              _buildField(
                'Nambari ya Simu',
                _phoneController,
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Jinsia',
                  prefixIcon: const Icon(
                    Icons.people_outline,
                    color: Color(0xFFC4620A),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFC4620A),
                      width: 1.5,
                    ),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'M',
                    child: Text('Mwanaume', style: GoogleFonts.inter()),
                  ),
                  DropdownMenuItem(
                    value: 'F',
                    child: Text('Mwanamke', style: GoogleFonts.inter()),
                  ),
                  DropdownMenuItem(
                    value: 'O',
                    child: Text('Nyingine', style: GoogleFonts.inter()),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC4620A),
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
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Hifadhi Mabadiliko',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  Widget _avatarFallback(AuthProvider auth) {
    return Container(
      color: const Color(0xFFC4620A),
      child: Center(
        child: Text(
          auth.userFullName.isNotEmpty ? auth.userFullName[0].toUpperCase() : 'K',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFC4620A)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFC4620A),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFB71C1C),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
