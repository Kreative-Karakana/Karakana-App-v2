import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  String _ticketType = 'general';
  bool _isSubmitting = false;

  static const _typeOptions = [
    ('technical', 'Technical Issue'),
    ('payment', 'Payment Issue'),
    ('content', 'Course Issue'),
    ('general', 'General Inquiry'),
    ('other', 'Other'),
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final dio = ApiClient.instance.dio;
      await dio.post(
        '/api/v1/communications/tickets/',
        data: {
          'subject': _subjectCtrl.text.trim(),
          'ticket_type': _ticketType,
          'message': _messageCtrl.text.trim(),
        },
      );
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ticket submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit ticket: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.grey, fontFamily: 'Inter'),
      filled: true,
      fillColor: AppColors.lightOrange,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'New Support Ticket',
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.dark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What do you need help with?',
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'We typically respond within 24 hours.',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _ticketType,
                decoration: _fieldDecoration('Issue Type'),
                dropdownColor: AppColors.white,
                style: TextStyle(
                  color: AppColors.dark,
                  fontFamily: 'Inter',
                  fontSize: 14,
                ),
                items: _typeOptions
                    .map(
                      (opt) => DropdownMenuItem(
                        value: opt.$1,
                        child: Text(opt.$2),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _ticketType = v ?? 'general'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectCtrl,
                decoration: _fieldDecoration('Subject'),
                style: TextStyle(
                  color: AppColors.dark,
                  fontFamily: 'Inter',
                  fontSize: 14,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Subject is required';
                  if (v.trim().length < 10) return 'Subject must be at least 10 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageCtrl,
                maxLines: 6,
                decoration: _fieldDecoration('Describe your issue'),
                style: TextStyle(
                  color: AppColors.dark,
                  fontFamily: 'Inter',
                  fontSize: 14,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Message is required';
                  if (v.trim().length < 20) return 'Message must be at least 20 characters';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _isSubmitting
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.dark, AppColors.primary],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Submit Ticket',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
