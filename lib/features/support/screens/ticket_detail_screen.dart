import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/top_popup.dart';

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
  bool _isUpdatingTicket = false;

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

  String _statusLabel(String? status) {
    switch (status) {
      case 'resolved':
      case 'closed':
        return 'Imemalizwa';
      case 'in_progress':
        return 'Inaendelea';
      default:
        return 'Wazi';
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

  Future<void> _editTicket() async {
    if (_ticket == null || _isUpdatingTicket) return;
    final subjectController = TextEditingController(
      text: _ticket!['subject'] as String? ?? '',
    );
    final descriptionController = TextEditingController(
      text: _ticket!['description'] as String? ?? '',
    );
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hariri Tiketi',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D1800),
          ),
        ),
        content: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration:
                    const InputDecoration(labelText: 'Kichwa cha Tiketi'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Maelezo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Ghairi',
              style: GoogleFonts.montserrat(color: const Color(0xFF9E8070)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE87722),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Hifadhi',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    final subject = subjectController.text.trim();
    final description = descriptionController.text.trim();
    subjectController.dispose();
    descriptionController.dispose();

    if (!mounted) return;
    if (shouldSave != true) return;
    if (subject.isEmpty) {
      showTopPopup(context, 'Kichwa cha tiketi kinahitajika.');
      return;
    }

    setState(() => _isUpdatingTicket = true);
    try {
      final payload = <String, dynamic>{'subject': subject};
      if (description.isNotEmpty) {
        payload['description'] = description;
      }
      await ApiClient().dio.patch(
            '/api/v1/communications/tickets/${widget.ticketId}/',
            data: payload,
          );
      await _loadData();
      if (!mounted) return;
      showTopPopup(context, 'Tiketi imehaririwa kikamilifu.', isError: false);
    } catch (_) {
      if (!mounted) return;
      showTopPopup(context, 'Imeshindikana kuhariri tiketi. Jaribu tena.');
    } finally {
      if (mounted) setState(() => _isUpdatingTicket = false);
    }
  }

  Future<void> _deleteTicket() async {
    if (_ticket == null || _isUpdatingTicket) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Futa Tiketi',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D1800),
          ),
        ),
        content: Text(
          'Una uhakika unataka kufuta tiketi hii? Hutaweza kuirejesha.',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: const Color(0xFF5C3D2E),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Ghairi',
              style: GoogleFonts.montserrat(color: const Color(0xFF9E8070)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Futa',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isUpdatingTicket = true);
    try {
      await ApiClient().dio.delete(
            '/api/v1/communications/tickets/${widget.ticketId}/',
          );
      if (!mounted) return;
      showTopPopup(context, 'Tiketi imefutwa kikamilifu.', isError: false);
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      showTopPopup(context, 'Imeshindikana kufuta tiketi. Jaribu tena.');
    } finally {
      if (mounted) setState(() => _isUpdatingTicket = false);
    }
  }

  Widget _metaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs / 2,
        vertical: AppSpacing.sm - AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EA),
        borderRadius: BorderRadius.circular(AppRadius.circle),
        border: Border.all(color: const Color(0xFFF0D5C3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: const Color(0xFF8C5D3D),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8F4),
        body: SafeArea(
            child: Center(
          child: KarakanaWaveLoader(color: Color(0xFFE87722)),
        )),
      );
    }
    if (_ticket == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF3D1800),
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: Center(
          child: Text(
            'Hatukuweza kufungua tiketi hii.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF9E8070),
            ),
          ),
        ),
      );
    }

    final isResolved =
        _ticket!['status'] == 'resolved' || _ticket!['status'] == 'closed';
    final createdAt = _formatTs(_ticket!['created_at'] as String?);
    final statusLabel = _statusLabel(_ticket!['status'] as String?);
    final description = (_ticket!['description'] as String? ?? '').trim();
    final subject = _ticket!['subject'] as String? ?? 'Tiketi';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                fontSize: AppTextStyles.caption.fontSize,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            Text(
              subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h4.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg - AppSpacing.xs,
              AppSpacing.sm + AppSpacing.xs,
              AppSpacing.lg - AppSpacing.xs,
              AppSpacing.sm + AppSpacing.xs,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + AppSpacing.xs / 2,
                      vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6D8),
                    borderRadius: BorderRadius.circular(
                        AppSpacing.sm + AppSpacing.xs / 2),
                  ),
                  child: Text(
                    'Msaada',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE87722),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + AppSpacing.xs / 2,
                      vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isResolved
                        ? const Color(0xFFF5E6D8)
                        : const Color(0xFFFFF8F4),
                    borderRadius: BorderRadius.circular(
                        AppSpacing.sm + AppSpacing.xs / 2),
                    border: Border.all(
                      color: isResolved
                          ? const Color(0xFFE87722)
                          : const Color(0xFFE87722),
                    ),
                  ),
                  child: Text(
                    isResolved ? 'Imemalizwa' : 'Wazi',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isResolved
                          ? const Color(0xFFE87722)
                          : const Color(0xFFE87722),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg - AppSpacing.xs,
              0,
              AppSpacing.lg - AppSpacing.xs,
              AppSpacing.sm + AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUpdatingTicket ? null : _editTicket,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE87722),
                      side: const BorderSide(color: Color(0xFFE87722)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppSpacing.sm + AppSpacing.xs),
                      ),
                    ),
                    icon: _isUpdatingTicket
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: KarakanaWaveLoader(strokeWidth: 2),
                          )
                        : const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      'Hariri Tiketi',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs / 2),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUpdatingTicket ? null : _deleteTicket,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC62828),
                      side: const BorderSide(color: Color(0xFFC62828)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppSpacing.sm + AppSpacing.xs),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(
                      'Futa Tiketi',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0E4DA)),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm + AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: const Color(0xFFF0E4DA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFE87722),
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Muhtasari wa Tiketi',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D1800),
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      height: 1.35,
                      color: const Color(0xFF6F5445),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs / 2),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm - AppSpacing.xs / 2,
                  children: [
                    _metaChip('Hali: $statusLabel'),
                    if (createdAt.isNotEmpty)
                      _metaChip('Imefunguliwa: $createdAt'),
                    _metaChip('Ujumbe: ${_messages.length}'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFBF8), Color(0xFFF7F1EC)],
                ),
              ),
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Hakuna ujumbe bado.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF9E8070),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: AppSpacing.cardPadding,
                      itemCount: _messages.length,
                      itemBuilder: (_, index) {
                        final msg = _messages[index];
                        final isStaff = msg['is_staff'] == true;
                        final isUser = !isStaff;
                        final ts =
                            _formatTs(msg['created_at'] as String? ?? '');
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
                                        horizontal:
                                            AppSpacing.md - AppSpacing.xs / 2,
                                        vertical:
                                            AppSpacing.sm + AppSpacing.xs / 2,
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
                                                fontSize: AppTextStyles
                                                    .caption.fontSize,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFFE87722),
                                              ),
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.xs),
                                          ],
                                          Text(
                                            msg['message'] as String? ?? '',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
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
                                      fontSize:
                                          AppTextStyles.labelSmall.fontSize,
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
          ),
          if (!isResolved)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Andika ujumbe...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFFBDA99C),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFFF8F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.modal),
                          borderSide:
                              const BorderSide(color: Color(0xFFE8D5C8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.modal),
                          borderSide: const BorderSide(
                            color: Color(0xFFE87722),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + AppSpacing.xs / 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
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
                              child: KarakanaWaveLoader(
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
              padding: AppSpacing.cardPadding,
              child: Text(
                'Tiketi hii imefungwa.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFFBDA99C),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
