import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
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
  final _service = EbookService();
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
    String provider = 'Mpesa';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nunua eBook'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Namba ya simu'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: provider,
              items: const ['Mpesa', 'Airtel', 'Tigo', 'Halopesa']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => provider = v ?? 'Mpesa',
              decoration: const InputDecoration(labelText: 'Mtandao'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ghairi')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Endelea')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processing = true);
    try {
      final result = await context.read<EbookProvider>().purchaseEbook(
            ebookId: widget.ebookId,
            accountNumber: phoneCtrl.text.trim(),
            provider: provider,
          );

      if (result == null) {
        throw Exception(context.read<EbookProvider>().purchaseError ?? 'Purchase failed');
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
          final statusRes = await ApiClient().dio.get('/api/v1/payments/$externalId/');
          if ((statusRes.data['is_successful'] == true) && mounted) {
            await context.read<EbookProvider>().fetchLibrary();
            await context.read<EbookProvider>().fetchStore();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Malipo yamekamilika. eBook imeongezwa kwenye maktaba.')),
              );
              context.push('/zana/ebooks/library');
            }
            break;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient().parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: KarakanaWaveLoader()));
    }

    final d = _detail ?? {};
    final isPurchased = d['is_purchased'] == true || context.watch<EbookProvider>().isOwned(widget.ebookId);
    final price = (d['price'] as num?)?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Maelezo ya Kitabu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: d['cover_image'] != null
                ? Image.network(d['cover_image'].toString(), fit: BoxFit.cover)
                : Container(color: const Color(0xFFF5E6D8), child: const Icon(Icons.menu_book_outlined, size: 48)),
          ),
          const SizedBox(height: 16),
          Text((d['title'] ?? '').toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text((d['author_name'] ?? '').toString()),
          const SizedBox(height: 12),
          Text((d['description'] ?? '').toString()),
          const SizedBox(height: 18),
          Text(price <= 0 ? 'Bure' : 'TZS $price', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _processing ? null : () {
              if (isPurchased) {
                context.push('/zana/ebooks/library');
              } else {
                _purchase();
              }
            },
            child: _processing ? const KarakanaWaveLoader(color: Colors.white, size: 12) : Text(isPurchased ? 'Soma' : 'Nunua'),
          ),
        ],
      ),
    );
  }
}
