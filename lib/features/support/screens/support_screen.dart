import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_client.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final response =
          await ApiClient().dio.get('/api/v1/communications/tickets/');
      final data = response.data;
      final rawList =
          data is Map ? (data['results'] as List? ?? const []) : const [];
      if (!mounted) return;
      setState(() {
        _tickets = rawList
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Msaada',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/support/new'),
        backgroundColor: const Color(0xFFE87722),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Tiketi Mpya',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Tunawezaje Kukusaidia?',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D1800),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickHelp(
                        Icons.help_outline,
                        'Maswali\nYaliyoulizwa',
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Inakuja hivi karibuni'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickHelp(
                        Icons.email_outlined,
                        'Tutumie\nBarua Pepe',
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('support@kreativekarakana.co.tz'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickHelp(
                        Icons.add_comment_outlined,
                        'Tiketi\nMpya',
                        () => context.push('/support/new'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0E4DA)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'Tiketi Zangu',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D1800),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_tickets.length} Tiketi',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: const Color(0xFF9E8070),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFFE87722)),
                  )
                : _tickets.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: const Color(0xFFE87722),
                        onRefresh: () async {
                          setState(() {
                            _isLoading = true;
                            _tickets = [];
                          });
                          await _loadTickets();
                        },
                        child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: _tickets.length,
                        itemBuilder: (_, index) {
                          final ticket = _tickets[index];
                          final isResolved = ticket['status'] == 'resolved' ||
                              ticket['status'] == 'closed';
                          final ticketId = ticket['id'] as int? ?? 0;
                          final subject =
                              ticket['subject'] as String? ?? 'Tiketi';
                          return GestureDetector(
                            onTap: () => context.push('/support/$ticketId'),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0FC4620A),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5E6D8),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: const Icon(
                                      Icons.support_agent_outlined,
                                      color: Color(0xFFE87722),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TKT-${ticketId.toString().padLeft(4, '0')}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 11,
                                            color: const Color(0xFFBDA99C),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          subject,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF3D1800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
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
                          );
                        },
                      ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelp(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8D5C8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFE87722), size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: const Color(0xFF5C3D2E),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFF5E6D8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_outlined,
              size: 48,
              color: Color(0xFFE87722),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Hakuna Tiketi Bado',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A0A00),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unda tiketi ili upate msaada.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF9E8070),
            ),
          ),
        ],
      ),
    );
  }
}
