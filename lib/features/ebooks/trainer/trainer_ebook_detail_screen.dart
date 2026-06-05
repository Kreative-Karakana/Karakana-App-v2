import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/karakana_wave_loader.dart';
import '../models/ebook.dart';
import '../services/ebook_service.dart';

class TrainerEbookDetailScreen extends StatefulWidget {
  final int ebookId;

  const TrainerEbookDetailScreen({super.key, required this.ebookId});

  @override
  State<TrainerEbookDetailScreen> createState() =>
      _TrainerEbookDetailScreenState();
}

class _TrainerEbookDetailScreenState extends State<TrainerEbookDetailScreen> {
  final _service = EbookService();
  final _currency = NumberFormat('#,###');

  Ebook? _ebook;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _ebook = await _service.fetchTrainerEbook(widget.ebookId);
    } catch (e) {
      _error = ApiClient().parseError(e);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _edit() async {
    final changed =
        await context.push<bool>('/trainer/ebooks/${widget.ebookId}/edit');
    if (changed == true && mounted) {
      await _load();
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa eBook'),
        content: const Text('Una uhakika unataka kufuta eBook hii?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Futa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteEbook(widget.ebookId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('eBook imefutwa kikamilifu.')),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient().parseError(e))),
      );
    }
  }

  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0xFFF1E4D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(color: const Color(0xFF1A0A00)),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFE87722)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF4D3A2A),
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0A00),
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ebook = _ebook;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2ED),
      appBar: AppBar(
        title: const Text('Maelezo ya eBook'),
        actions: [
          IconButton(
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Hariri',
          ),
          IconButton(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Futa',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: KarakanaWaveLoader())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: AppSpacing.screenPadding,
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge,
                    ),
                  ),
                )
              : ebook == null
                  ? const Center(child: Text('eBook haikupatikana.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3D1800), Color(0xFFE87722)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE87722)
                                      .withValues(alpha: 0.24),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    width: 98,
                                    height: 132,
                                    color: Colors.white.withValues(alpha: 0.12),
                                    child: ebook.coverImageUrl != null &&
                                            ebook.coverImageUrl!.isNotEmpty
                                        ? Image.network(
                                            ebook.coverImageUrl!,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(
                                            Icons.menu_book_rounded,
                                            size: 42,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.18,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          ebook.status.toUpperCase(),
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        ebook.title,
                                        style: AppTextStyles.h2.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        ebook.description,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.1,
                            children: [
                              _metricCard(
                                icon: Icons.people_alt_outlined,
                                label: 'Wateja wa kipekee',
                                value: '${ebook.buyersCount}',
                                accent: const Color(0xFFE87722),
                              ),
                              _metricCard(
                                icon: Icons.shopping_bag_outlined,
                                label: 'Mauzo yaliyofaulu',
                                value: '${ebook.successfulPurchasesCount}',
                                accent: const Color(0xFF3D1800),
                              ),
                              _metricCard(
                                icon: Icons.payments_outlined,
                                label: 'Mapato',
                                value:
                                    'TZS ${_currency.format(ebook.totalRevenue)}',
                                accent: const Color(0xFF2E7D32),
                              ),
                              _metricCard(
                                icon: Icons.menu_book_outlined,
                                label: 'Kurasa',
                                value: '${ebook.totalPages}',
                                accent: const Color(0xFF1565C0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              border:
                                  Border.all(color: const Color(0xFFF1E4D8)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Taarifa za eBook',
                                  style: AppTextStyles.h3.copyWith(
                                    color: const Color(0xFF1A0A00),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _infoRow(
                                  Icons.price_change_outlined,
                                  'Bei',
                                  'TZS ${_currency.format(ebook.priceInTzs)}',
                                ),
                                _infoRow(
                                  Icons.calendar_today_outlined,
                                  'Iliundwa',
                                  ebook.createdAt == null
                                      ? '-'
                                      : DateFormat(
                                          'dd MMM yyyy',
                                        ).format(ebook.createdAt!),
                                ),
                                _infoRow(
                                  Icons.update_outlined,
                                  'Imesasishwa',
                                  ebook.updatedAt == null
                                      ? '-'
                                      : DateFormat(
                                          'dd MMM yyyy',
                                        ).format(ebook.updatedAt!),
                                ),
                                _infoRow(
                                  Icons.lock_outline,
                                  'Hali',
                                  ebook.status,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _edit,
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Hariri'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _delete,
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Futa'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFB71C1C),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }
}
