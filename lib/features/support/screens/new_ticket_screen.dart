import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_client.dart';
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
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aina ya Tatizo',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D1800),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: issueTypes.map((type) {
                  final isSelected = _selectedType == type[0];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type[0] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE87722)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                          const SizedBox(width: 6),
                          Text(
                            type[1] as String,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
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
              const SizedBox(height: 20),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Mada',
                  hintText: 'Elezea tatizo lako kwa ufupi...',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE87722),
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'Weka mada ya tiketi'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Ujumbe',
                  hintText: 'Elezea tatizo lako kwa undani...',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE87722),
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Weka ujumbe' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE87722),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitTicket,
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
                          'Tuma Tiketi',
                          style: GoogleFonts.montserrat(
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
