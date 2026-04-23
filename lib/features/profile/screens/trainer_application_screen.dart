import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_client.dart';

class TrainerApplicationScreen extends StatefulWidget {
  const TrainerApplicationScreen({super.key});

  @override
  State<TrainerApplicationScreen> createState() =>
      _TrainerApplicationScreenState();
}

class _TrainerApplicationScreenState extends State<TrainerApplicationScreen> {
  Map<String, dynamic>? _existingApplication;
  bool _isLoading = true;
  bool _isSubmitting = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _whyController = TextEditingController();
  final TextEditingController _topicsController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
    super.dispose();
  }

  Future<void> _loadApplication() async {
    try {
      final res = await ApiClient().dio.get('/api/v1/trainer-application/');
      final data = res.data;
      final results =
          data is Map ? (data['results'] as List? ?? []) : (data as List? ?? []);
      if (!mounted) return;
      setState(() {
        _existingApplication =
            results.isNotEmpty ? Map<String, dynamic>.from(results.first as Map) : null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
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
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ombi limetumwa! Tutakujibu hivi karibuni.'),
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
      if (mounted) setState(() => _isSubmitting = false);
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
          'Omba Kuwa Mwalimu',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC4620A)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC4620A), Color(0xFFE07030)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kuwa Mwalimu Karakana',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Shiriki ujuzi wako na upate kipato kwa kufundisha wengine.',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
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
                  const SizedBox(height: 28),
                  if (_existingApplication != null)
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
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Weka cheo chako' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            'Wasifu wa Kitaaluma',
                            _bioController,
                            hint: 'Elezea ujuzi wako na uzoefu...',
                            maxLines: 4,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Weka wasifu wako' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            'Uzoefu wa Kufundisha',
                            _experienceController,
                            hint: 'Je, umewahi kufundisha kabla? Elezea...',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            'Kwa Nini Unataka Kufundisha?',
                            _whyController,
                            hint: 'Shiriki sababu yako...',
                            maxLines: 3,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Weka sababu yako'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            'Mada za Kufundisha',
                            _topicsController,
                            hint: 'Mfano: Ujasiriamali, Fedha, Uongozi',
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Weka mada zako' : null,
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC4620A),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              onPressed:
                                  _isSubmitting ? null : _submitApplication,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Tuma Ombi',
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
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(Map application) {
    final status = application['status'] as String? ?? 'pending';
    final color = status == 'approved'
        ? const Color(0xFF2E7D32)
        : status == 'rejected'
            ? const Color(0xFFB71C1C)
            : const Color(0xFFE65100);
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3B1A08),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
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
