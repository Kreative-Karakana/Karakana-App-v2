import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/common/karakana_wave_loader.dart';
import '../../../widgets/common/top_popup.dart';
import '../models/ebook.dart';
import '../providers/ebook_provider.dart';
import '../services/ebook_service.dart';

class TrainerEbooksScreen extends StatefulWidget {
  const TrainerEbooksScreen({super.key});

  @override
  State<TrainerEbooksScreen> createState() => _TrainerEbooksScreenState();
}

class _TrainerEbooksScreenState extends State<TrainerEbooksScreen> {
  final _service = EbookService();

  // ── HELPERS ───────────────────────────────────────────────────────────────

  String _fmt(num n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'published':
        return 'Imechapishwa';
      case 'pending_review':
        return 'Inasubiri';
      default:
        return 'Rasimu';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'published':
        return const Color(0xFF2E7D32);
      case 'pending_review':
        return const Color(0xFFE87722);
      default:
        return const Color(0xFF6B7280);
    }
  }

  // ── ACTIONS ───────────────────────────────────────────────────────────────

  Future<void> _refresh() => context.read<EbookProvider>().fetchMyEbooks();

  Future<void> _togglePublish(Ebook e) async {
    final isPublished = e.status == 'published';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isPublished ? 'Ficha eBook?' : 'Chapisha eBook?',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        content: Text(
          isPublished
              ? 'eBook itafichwa na wateja hawataweza kuinunua tena.'
              : 'eBook itaonekana kwa wateja na itaweza kununuliwa.',
          style: GoogleFonts.montserrat(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hapana', style: GoogleFonts.montserrat()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPublished
                  ? const Color(0xFF3D1800)
                  : const Color(0xFFE87722),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isPublished ? 'Ndiyo, Ficha' : 'Chapisha',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.updateEbook(
        id: e.id,
        data: {'status': isPublished ? 'draft' : 'published'},
      );
      if (!mounted) return;
      showTopPopup(
        context,
        isPublished
            ? 'eBook imefichwa.'
            : 'eBook imechapishwa na inaonekana kwa wateja.',
        isError: false,
      );
      await _refresh();
    } catch (err) {
      if (!mounted) return;
      showTopPopup(context, ApiClient().parseError(err));
    }
  }

  Future<void> _delete(Ebook e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Futa eBook?',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: Text(
          'Una uhakika unataka kufuta "${e.title}"? Hatua hii haiwezi kutenduliwa.',
          style: GoogleFonts.montserrat(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hapana', style: GoogleFonts.montserrat()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Futa',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<EbookProvider>().deleteEbook(e.id);
      if (!mounted) return;
      showTopPopup(context, 'eBook imefutwa.', isError: false);
    } catch (err) {
      if (!mounted) return;
      showTopPopup(context, ApiClient().parseError(err));
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A0A00) : const Color(0xFFFFF8F4);
    final surfaceColor = isDark ? const Color(0xFF2A1400) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A0A00);

    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer<EbookProvider>(
        builder: (_, provider, __) {
          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              _buildAppBar(provider),
            ],
            body: provider.isLoadingMyEbooks
                ? const Center(
                    child: KarakanaWaveLoader(color: Color(0xFFE87722)))
                : RefreshIndicator(
                    color: const Color(0xFFE87722),
                    onRefresh: _refresh,
                    child: provider.myEbooks.isEmpty
                        ? _buildEmptyState(surfaceColor)
                        : _buildList(
                            provider, bgColor, surfaceColor, textPrimary),
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/trainer/ebooks/add');
          if (mounted) await _refresh();
        },
        backgroundColor: const Color(0xFFE87722),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  // ── SLIVER APP BAR ────────────────────────────────────────────────────────

  Widget _buildAppBar(EbookProvider provider) {
    final ebooks = provider.myEbooks;
    final totalReaders = ebooks.fold<int>(0, (s, e) => s + e.buyersCount);
    final totalRevenue = ebooks.fold<double>(0, (s, e) => s + e.totalRevenue);
    final published = ebooks.where((e) => e.status == 'published').length;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF3D1800),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon:
              const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
          onPressed: _refresh,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3D1800), Color(0xFF7B3A10)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 36), // below leading
                  Text(
                    'Vitabu vya Kidijitali',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Simamia eBooks zako na fuatilia mauzo',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── 4-chip stats strip ──
                  Row(
                    children: [
                      _heroChip(Icons.menu_book_outlined, '${ebooks.length}',
                          'Vitabu'),
                      const SizedBox(width: 8),
                      _heroChip(
                          Icons.people_outline, _fmt(totalReaders), 'Wasomaji'),
                      const SizedBox(width: 8),
                      _heroChip(
                        Icons.payments_outlined,
                        AppFormatters.currency(
                          totalRevenue,
                          compact: true,
                        ),
                        'Mapato',
                      ),
                      const SizedBox(width: 8),
                      _heroChip(Icons.check_circle_outline, '$published',
                          'Zilizochapishwa'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'Vitabu vya Kidijitali',
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _heroChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 8.5,
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── LIST ──────────────────────────────────────────────────────────────────

  Widget _buildList(EbookProvider provider, Color bgColor, Color surfaceColor,
      Color textPrimary) {
    final ebooks = provider.myEbooks;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: ebooks.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildEbookCard(ebooks[i], surfaceColor, textPrimary),
      ),
    );
  }

  // ── EBOOK CARD ────────────────────────────────────────────────────────────

  Widget _buildEbookCard(Ebook e, Color surfaceColor, Color textPrimary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(e.status);
    final label = _statusLabel(e.status);
    final isPublished = e.status == 'published';
    final isPending = e.status == 'pending_review';

    return GestureDetector(
      onTap: () async {
        await context.push('/trainer/ebooks/${e.id}');
        if (mounted) await _refresh();
      },
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE87722).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── COVER + STATUS BADGE ──
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: e.coverImageUrl != null &&
                            e.coverImageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: e.coverImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _coverFallback(isDark),
                            errorWidget: (_, __, ___) => _coverFallback(isDark),
                          )
                        : _coverFallback(isDark),
                  ),
                  // gradient scrim
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF1A0A00).withValues(alpha: 0.55),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // status badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            label,
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── CONTENT ──
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title
                  Text(
                    e.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // ── STATS ROW ──
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 13, color: Color(0xFF7B3A10)),
                      const SizedBox(width: 4),
                      Text(
                        '${e.buyersCount} wasomaji',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7B3A10),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.shopping_bag_outlined,
                          size: 13, color: Color(0xFF7B3A10)),
                      const SizedBox(width: 4),
                      Text(
                        '${e.successfulPurchasesCount} mauzo',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7B3A10),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AppFormatters.currency(
                          e.priceInTzs,
                          zeroLabel: 'Bure',
                        ),
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE87722),
                        ),
                      ),
                    ],
                  ),

                  if (e.successfulPurchasesCount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            size: 13, color: Color(0xFF7B3A10)),
                        const SizedBox(width: 4),
                        Text(
                          'Mapato: ${AppFormatters.currency(e.totalRevenue)}',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7B3A10),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : const Color(0xFFF5E6D8),
                  ),
                  const SizedBox(height: 10),

                  // ── ACTION BUTTONS ──
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // Publish/unpublish toggle
                      GestureDetector(
                        onTap: isPending ? null : () => _togglePublish(e),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPublished
                                    ? Icons.visibility_outlined
                                    : isPending
                                        ? Icons.hourglass_top_rounded
                                        : Icons.visibility_off_outlined,
                                size: 13,
                                color: statusColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                label,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _actionChip(
                        'Hariri',
                        Icons.edit_outlined,
                        () async {
                          await context.push('/trainer/ebooks/${e.id}/edit');
                          if (mounted) await _refresh();
                        },
                        isDark: isDark,
                      ),
                      _actionChip(
                        'Maelezo',
                        Icons.bar_chart_rounded,
                        () async {
                          await context.push('/trainer/ebooks/${e.id}');
                          if (mounted) await _refresh();
                        },
                        isDark: isDark,
                      ),
                      _actionChip(
                        'Futa',
                        Icons.delete_outline_rounded,
                        () => _delete(e),
                        isDark: isDark,
                        isDanger: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverFallback(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8),
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book_outlined,
          color: Color(0xFFE87722), size: 44),
    );
  }

  Widget _actionChip(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isDark = false,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isDanger
              ? const Color(0xFFB71C1C).withValues(alpha: 0.08)
              : (isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8)),
          border: Border.all(
            color: isDanger
                ? const Color(0xFFB71C1C).withValues(alpha: 0.25)
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 12,
                color: isDanger
                    ? const Color(0xFFB71C1C)
                    : const Color(0xFF7B3A10)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDanger
                    ? const Color(0xFFB71C1C)
                    : const Color(0xFF7B3A10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────

  Widget _buildEmptyState(Color surfaceColor) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5E6D8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_outlined,
                    size: 44, color: Color(0xFFE87722)),
              ),
              const SizedBox(height: 20),
              Text(
                'Huna eBook bado.\nBonyeza + kupakia eBook yako ya kwanza!',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7B3A10),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await context.push('/trainer/ebooks/add');
                  if (mounted) await _refresh();
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Pakia eBook',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE87722),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
