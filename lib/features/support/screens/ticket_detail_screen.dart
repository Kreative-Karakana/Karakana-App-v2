import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _ticket;
  List<Map<String, dynamic>> _messages = [];

  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ApiClient.instance.dio;
      final results = await Future.wait([
        dio.get('/api/v1/communications/tickets/${widget.ticketId}/'),
        dio.get('/api/v1/communications/tickets/${widget.ticketId}/messages/'),
      ]);

      final ticketData = results[0].data;
      final msgData = results[1].data;

      List<dynamic> rawMessages;
      if (msgData is List) {
        rawMessages = msgData;
      } else if (msgData is Map && msgData.containsKey('results')) {
        rawMessages = msgData['results'] as List<dynamic>? ?? [];
      } else {
        rawMessages = [];
      }

      setState(() {
        _ticket = ticketData as Map<String, dynamic>?;
        _messages = rawMessages.cast<Map<String, dynamic>>();
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.get(
        '/api/v1/communications/tickets/${widget.ticketId}/messages/',
      );
      final data = response.data;
      List<dynamic> raw;
      if (data is List) {
        raw = data;
      } else if (data is Map && data.containsKey('results')) {
        raw = data['results'] as List<dynamic>? ?? [];
      } else {
        raw = [];
      }
      setState(() => _messages = raw.cast<Map<String, dynamic>>());
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final dio = ApiClient.instance.dio;
      await dio.post(
        '/api/v1/communications/tickets/${widget.ticketId}/messages/',
        data: {'message': text},
      );
      _messageCtrl.clear();
      await _fetchMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  String _formatType(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'technical':
        return 'Technical Issue';
      case 'payment':
      case 'billing':
        return 'Payment Issue';
      case 'content':
        return 'Course Issue';
      case 'general':
        return 'General Inquiry';
      default:
        return raw ?? 'General';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    final status = ticket?['status']?.toString() ?? 'open';
    final isResolved = status == 'resolved' || status == 'closed';
    final number = ticket?['number']?.toString() ??
        widget.ticketId.toString();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Text(
              'Ticket #$number',
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isResolved
                    ? Colors.green.shade600
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isResolved ? 'Resolved' : 'Open',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: AppColors.dark),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
          ? _ErrorView(error: _error!, onRetry: _fetch)
          : Column(
              children: [
                // ── Ticket info card ──────────────────
                if (ticket != null)
                  _TicketInfoCard(
                    subject: ticket['subject']?.toString() ?? '',
                    type: _formatType(ticket['ticket_type']?.toString()),
                    date: _formatDate(ticket['created_at']?.toString()),
                  ),
                const Divider(height: 1),

                // ── Messages ─────────────────────────
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            'No messages yet.\nSend a message below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 14,
                              fontFamily: 'Inter',
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final msg = _messages[i];
                            final isStaff =
                                msg['is_staff'] as bool? ?? false;
                            final text =
                                msg['message']?.toString() ?? '';
                            final time = _formatDate(
                              msg['created_at']?.toString(),
                            );
                            return _MessageBubble(
                              text: text,
                              time: time,
                              isStaff: isStaff,
                            );
                          },
                        ),
                ),

                // ── Input row ────────────────────────
                _MessageInput(
                  controller: _messageCtrl,
                  isSending: _isSending,
                  onSend: _sendMessage,
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────
// Ticket info card
// ─────────────────────────────────────────────

class _TicketInfoCard extends StatelessWidget {
  const _TicketInfoCard({
    required this.subject,
    required this.type,
    required this.date,
  });

  final String subject;
  final String type;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.lightOrange,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject,
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                type,
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
              if (date.isNotEmpty) ...[
                Text(
                  '  ·  $date',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Message bubble
// ─────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isStaff,
  });

  final String text;
  final String time;
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isStaff ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (isStaff)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                'Support Team',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isStaff ? AppColors.lightGrey : AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isStaff ? 4 : 16),
                bottomRight: Radius.circular(isStaff ? 16 : 4),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isStaff ? AppColors.dark : Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
          ),
          if (time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                time,
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 10,
                  fontFamily: 'Inter',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Message input
// ─────────────────────────────────────────────

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: AppColors.grey,
                  fontFamily: 'Inter',
                ),
                filled: true,
                fillColor: AppColors.lightOrange,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: AppColors.dark, fontFamily: 'Inter'),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 4),
          isSending
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: onSend,
                  icon: Icon(Icons.send_rounded, color: AppColors.primary),
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
