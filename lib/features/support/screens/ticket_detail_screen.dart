import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Map<String, dynamic>? _ticket;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTs(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('HH:mm dd/MM/yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  Future<void> _loadData() async {
    try {
      final ticketRes = await ApiClient()
          .dio
          .get('/api/v1/communications/tickets/${widget.ticketId}/');
      final messagesRes = await ApiClient()
          .dio
          .get('/api/v1/communications/tickets/${widget.ticketId}/messages/');
      if (!mounted) return;
      final data = messagesRes.data;
      setState(() {
        _ticket = Map<String, dynamic>.from(ticketRes.data as Map);
        _messages = (data is Map
                ? (data['results'] as List? ?? const [])
                : (data as List? ?? const []))
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;
    final text = _messageController.text;
    _messageController.clear();
    setState(() => _isSending = true);
    try {
      final res = await ApiClient().dio.post(
        '/api/v1/communications/tickets/${widget.ticketId}/messages/',
        data: {'message': text},
      );
      if (!mounted) return;
      setState(() {
        _messages.add(Map<String, dynamic>.from(res.data as Map));
        _isSending = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8F4),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE87722)),
        ),
      );
    }
    if (_ticket == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F4),
        appBar: AppBar(
          backgroundColor: const Color(0xFF3D1800),
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: Center(
          child: Text(
            'Hatukuweza kufungua tiketi hii.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF9E8070),
            ),
          ),
        ),
      );
    }

    final isResolved = _ticket!['status'] == 'resolved' ||
        _ticket!['status'] == 'closed';
    final subject = _ticket!['subject'] as String? ?? 'Tiketi';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TKT-${widget.ticketId.toString().padLeft(4, '0')}',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            Text(
              subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6D8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Msaada',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE87722),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isResolved
                        ? const Color(0xFFF5E6D8)
                        : const Color(0xFFFFF8F4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isResolved
                          ? const Color(0xFFE87722)
                          : const Color(0xFFE87722),
                    ),
                  ),
                  child: Text(
                    isResolved ? 'Imemalizwa' : 'Wazi',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isResolved
                          ? const Color(0xFFE87722)
                          : const Color(0xFFE87722),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0E4DA)),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Hakuna ujumbe bado.',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: const Color(0xFF9E8070),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, index) {
                      final msg = _messages[index];
                      final isStaff = msg['is_staff'] == true;
                      final isUser = !isStaff;
                      final ts = _formatTs(
                          msg['created_at'] as String? ?? '');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: isUser
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (isStaff) ...[
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFE87722),
                                          Color(0xFFFFA726)
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.support_agent,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.72,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? const Color(0xFFE87722)
                                          : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft:
                                            Radius.circular(isUser ? 16 : 4),
                                        bottomRight:
                                            Radius.circular(isUser ? 4 : 16),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (isStaff) ...[
                                          Text(
                                            'Msaada wa Karakana',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFE87722),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        Text(
                                          msg['message'] as String? ?? '',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            height: 1.4,
                                            color: isUser
                                                ? Colors.white
                                                : const Color(0xFF3D1800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isUser) const SizedBox(width: 8),
                              ],
                            ),
                            if (ts.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 3,
                                  left: isStaff ? 40 : 0,
                                  right: isUser ? 8 : 0,
                                  bottom: 8,
                                ),
                                child: Text(
                                  ts,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    color: const Color(0xFFBDA99C),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (!isResolved)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Andika ujumbe...',
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: const Color(0xFFBDA99C),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFFF8F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: Color(0xFFE8D5C8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFFE87722),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isSending ? null : _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE87722), Color(0xFFFFA726)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tiketi hii imefungwa.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: const Color(0xFFBDA99C),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
