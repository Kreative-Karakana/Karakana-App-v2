import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/top_popup.dart';

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  String? _selectedType;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const issueTypes = [
      ['ACC', 'Akaunti Yangu', Icons.person_outline],
      ['CSR', 'Kozi', Icons.school_outlined],
      ['BIL', 'Malipo', Icons.payment_outlined],
      ['TEC', 'Kiufundi', Icons.build_outlined],
      ['OTH', 'Nyingine', Icons.help_outline],
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Tiketi Mpya',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: AppSpacing.sectionPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aina ya Tatizo',
                style: AppTextStyles.h4.copyWith(color: const Color(0xFF3D1800)),
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: issueTypes.map((type) {
                  final isSelected = _selectedType == type[0];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedType = type[0] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md - AppSpacing.xs / 2,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFFE87722) : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFE87722)
                              : const Color(0xFFE8D5C8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type[2] as IconData,
                            size: 14,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF9E8070),
                          ),
                          const SizedBox(width: AppSpacing.sm - AppSpacing.xs / 2),
                          Text(
                            type[1] as String,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF5C3D2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg - AppSpacing.xs),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Mada',
                  hintText: 'Elezea tatizo lako kwa ufupi...',
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
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Weka mada ya tiketi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Ujumbe',
                  hintText: 'Elezea tatizo lako kwa undani...',
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
                ),
                validator: (v) => v == null || v.isEmpty ? 'Weka ujumbe' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE87722),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitTicket,
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
                          'Tuma Tiketi',
                          style: AppTextStyles.buttonLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      )),
    );
  }

  Future<void> _submitTicket() async {
    if (_selectedType == null) {
      showTopPopup(context, 'Chagua aina ya tatizo');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final ticketRes = await ApiClient().dio.post(
        '/api/v1/communications/tickets/',
        data: {
          'subject': _subjectController.text,
          'type': _selectedType,
        },
      );
      final dynamic ticketData = ticketRes.data;
      final int? ticketId = ticketData is Map
          ? (ticketData['id'] as int? ??
              (ticketData['ticket'] is Map
                  ? (ticketData['ticket']['id'] as int?)
                  : null))
          : null;
      if (ticketId == null) {
        throw Exception('Ticket ID missing from response');
      }
      await ApiClient().dio.post(
        '/api/v1/communications/tickets/$ticketId/messages/',
        data: {'message': _messageController.text},
      );
      if (!mounted) return;
      showTopPopup(context, 'Tiketi imesajiliwa kikamilifu!', isError: false);
      // Go directly into the new ticket thread
      context.pushReplacement('/support/$ticketId');
    } catch (_) {
      if (!mounted) return;
      showTopPopup(context, 'Hitilafu. Jaribu tena.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
