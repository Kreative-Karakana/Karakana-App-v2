import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/karakana_wave_loader.dart';
import '../providers/ebook_provider.dart';
import '../services/ebook_service.dart';

class EbookDetailScreen extends StatefulWidget {
  final int ebookId;
  const EbookDetailScreen({super.key, required this.ebookId});

  @override
  State<EbookDetailScreen> createState() => _EbookDetailScreenState();
}

class _EbookDetailScreenState extends State<EbookDetailScreen> {
  static const _headerGradient = [
    Color(0xFF1A0A00),
    Color(0xFF3D1800),
    Color(0xFF7B3A10),
  ];
  final _service = EbookService();
  final _currency = NumberFormat('#,###');
  Map<String, dynamic>? _detail;
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final e = await _service.fetchDetail(widget.ebookId);
      _detail = {
        'id': e.id,
        'title': e.title,
        'description': e.description,
        'author_name': e.authorName,
        'cover_image': e.coverImageUrl,
        'price': e.priceInTzs,
        'is_purchased': e.isPurchased,
      };
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purchase() async {
    final phoneCtrl = TextEditingController();
    final ebookProvider = context.read<EbookProvider>();
    String provider = 'Mpesa';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE87722).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFFE87722),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Malipo ya eBook',
                    style: AppTextStyles.h3.copyWith(
                      color: const Color(0xFF1A0A00),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Weka namba ya simu na chagua mtandao wa malipo.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF5ED), Color(0xFFFFE8D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF7B3A10),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Malipo yatafungua PDF hii kwenye maktaba yako ya kidigitali.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF7B3A10),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Namba ya simu',
                hintText: 'Mfano 07XXXXXXXX',
                prefixIcon: const Icon(Icons.phone_android_outlined),
                filled: true,
                fillColor: const Color(0xFFF7F7F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            DropdownButtonFormField<String>(
              initialValue: provider,
              items: const ['Mpesa', 'Airtel', 'Tigo', 'Halopesa']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => provider = v ?? 'Mpesa',
              decoration: InputDecoration(
                labelText: 'Mtandao',
                prefixIcon: const Icon(Icons.sim_card_outlined),
                filled: true,
                fillColor: const Color(0xFFF7F7F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Ghairi'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Endelea'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processing = true);
    try {
      final result = await ebookProvider.purchaseEbook(
        ebookId: widget.ebookId,
        accountNumber: phoneCtrl.text.trim(),
        provider: provider,
      );

      if (result == null) {
        throw Exception(
          ebookProvider.purchaseError ??
              'Ununuzi umeshindikana. Tafadhali jaribu tena.',
        );
      }

      final payment = (result['payment'] as Map?)?.cast<String, dynamic>();
      final checkoutUrl = payment?['checkout_url']?.toString();
      final externalId = payment?['external_id']?.toString();

      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        final uri = Uri.parse(checkoutUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (externalId != null && externalId.isNotEmpty) {
        for (var i = 0; i < 10; i++) {
          await Future.delayed(const Duration(seconds: 3));
          final statusRes =
              await ApiClient().dio.get('/api/v1/payments/$externalId/');
          if ((statusRes.data['is_successful'] == true) && mounted) {
            await ebookProvider.fetchLibrary();
            await ebookProvider.fetchStore();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Malipo yamekamilika. eBook imeongezwa kwenye maktaba.')),
              );
              context.push('/zana/ebooks/library');
            }
            break;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ApiClient().parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: KarakanaWaveLoader()),
        ),
      );
    }

    final d = _detail ?? {};
    final isPurchased = d['is_purchased'] == true ||
        context.watch<EbookProvider>().isOwned(widget.ebookId);
    final price = (d['price'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: _headerGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_outlined,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Maelezo ya eBook',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3D1800).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: AspectRatio(
                      aspectRatio: 0.74,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: d['cover_image'] != null
                            ? Image.network(
                                d['cover_image'].toString(),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: const Color(0xFFF5E6D8),
                                child: const Icon(
                                  Icons.menu_book_outlined,
                                  size: 48,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        height: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1A0A00),
                              Color(0xFF3D1800),
                              Color(0xFF7B3A10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B3A10)
                                  .withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_outlined,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'PDF',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              price <= 0
                                  ? 'Bure'
                                  : 'TZS ${_currency.format(price)}',
                              style: AppTextStyles.price.copyWith(
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPurchased
                                        ? Icons.check_circle_outline
                                        : Icons.bookmark_outline,
                                    size: 15,
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isPurchased
                                          ? 'Ipo maktabani'
                                          : 'Nunua kusoma',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((d['title'] ?? '').toString(), style: AppTextStyles.h1),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    (d['author_name'] ?? '').toString(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    (d['description'] ?? '').toString(),
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _processing
                          ? null
                          : () {
                              if (isPurchased) {
                                context.push(
                                  '/zana/ebooks/read/${widget.ebookId}',
                                  extra: {
                                    'ebookTitle':
                                        (d['title'] ?? 'eBook').toString()
                                  },
                                );
                              } else {
                                _purchase();
                              }
                            },
                      child: _processing
                          ? const KarakanaWaveLoader(
                              color: Colors.white,
                              size: 12,
                            )
                          : Text(isPurchased ? 'Soma' : 'Nunua'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
