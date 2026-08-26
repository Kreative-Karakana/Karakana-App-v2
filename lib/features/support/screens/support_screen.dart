import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/top_popup.dart';
import '../../../widgets/common/empty_state_view.dart';

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
      final List<dynamic> rawList;
      if (data is List) {
        rawList = data;
      } else if (data is Map && data['results'] is List) {
        rawList = data['results'] as List;
      } else {
        rawList = const [];
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Msaada',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/support/new');
          if (!mounted) return;
          await _loadTickets();
        },
        backgroundColor: const Color(0xFFE87722),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Tiketi Mpya',
          style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
          child: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            padding: AppSpacing.cardPadding,
            child: Column(
              children: [
                Text(
                  'Tunawezaje Kukusaidia?',
                  style:
                      AppTextStyles.h4.copyWith(color: const Color(0xFF3D1800)),
                ),
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickHelp(
                        Icons.help_outline,
                        'Maswali\nYaliyoulizwa',
                        () => showTopPopup(context, 'Inakuja hivi karibuni',
                            isError: false),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + AppSpacing.xs / 2),
                    Expanded(
                      child: _buildQuickHelp(
                        Icons.email_outlined,
                        'Tutumie\nBarua Pepe',
                        () => showTopPopup(
                            context, 'support@kreativekarakana.co.tz',
                            isError: false),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + AppSpacing.xs / 2),
                    Expanded(
                      child: _buildQuickHelp(
                        Icons.add_comment_outlined,
                        'Tiketi\nMpya',
                        () async {
                          await context.push('/support/new');
                          if (!mounted) return;
                          await _loadTickets();
                        },
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.white10 : const Color(0xFFF0E4DA)),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg - AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.lg - AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  'Tiketi Zangu',
                  style: AppTextStyles.h4.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        const Color(0xFF1A0A00),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_tickets.length} Tiketi',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF9E8070),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: KarakanaWaveLoader(color: Color(0xFFE87722)),
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
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg - AppSpacing.xs,
                            0,
                            AppSpacing.lg - AppSpacing.xs,
                            80,
                          ),
                          itemCount: _tickets.length,
                          itemBuilder: (_, index) {
                            final ticket = _tickets[index];
                            final isResolved = ticket['status'] == 'resolved' ||
                                ticket['status'] == 'closed';
                            final ticketId = ticket['id'] as int? ?? 0;
                            final subject =
                                ticket['subject'] as String? ?? 'Tiketi';
                            return GestureDetector(
                              onTap: () async {
                                final result =
                                    await context.push('/support/$ticketId');
                                if (!mounted) return;
                                if (result == true) {
                                  await _loadTickets();
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: AppSpacing.sm + AppSpacing.xs / 2),
                                padding: const EdgeInsets.all(
                                    AppSpacing.md - AppSpacing.xs / 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.input),
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
                                        color: isDark
                                            ? const Color(0xFF2A1A0A)
                                            : const Color(0xFFF5E6D8),
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.sm + AppSpacing.xs - 1),
                                      ),
                                      child: const Icon(
                                        Icons.support_agent_outlined,
                                        color: Color(0xFFE87722),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(
                                        width: AppSpacing.sm + AppSpacing.xs),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'TKT-${ticketId.toString().padLeft(4, '0')}',
                                            style: GoogleFonts.montserrat(
                                              fontSize: AppTextStyles
                                                  .caption.fontSize,
                                              color: const Color(0xFFBDA99C),
                                            ),
                                          ),
                                          const SizedBox(
                                              height: AppSpacing.xs / 2),
                                          Text(
                                            subject,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.labelLarge
                                                .copyWith(
                                              color: const Color(0xFF3D1800),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            AppSpacing.sm + AppSpacing.xs / 2,
                                        vertical: AppSpacing.xs,
                                      ),
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
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
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
      )),
    );
  }

  Widget _buildQuickHelp(
    IconData icon,
    String label,
    VoidCallback onTap, {
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFFFF8F4),
          borderRadius: BorderRadius.circular(AppSpacing.sm + AppSpacing.xs),
          border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE8D5C8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFE87722), size: 24),
            const SizedBox(height: AppSpacing.sm - AppSpacing.xs / 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
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
    return const EmptyStateView(
      icon: Icons.support_agent_outlined,
      title: 'Hakuna Tiketi Bado',
      subtitle: 'Unda tiketi ili upate msaada.',
    );
  }
}
