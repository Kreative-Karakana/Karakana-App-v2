import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../widgets/common/karakana_wave_loader.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/ebook_provider.dart';

class TrainerEbooksScreen extends StatefulWidget {
  const TrainerEbooksScreen({super.key});

  @override
  State<TrainerEbooksScreen> createState() => _TrainerEbooksScreenState();
}

class _TrainerEbooksScreenState extends State<TrainerEbooksScreen> {
  final _currency = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EbookProvider>().fetchMyEbooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vitabu Vyangu')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/trainer/ebooks/add'),
        child: const Icon(Icons.add),
      ),
      body: Consumer<EbookProvider>(
        builder: (_, provider, __) {
          if (provider.isLoadingMyEbooks) {
            return const Center(child: KarakanaWaveLoader());
          }
          if (provider.myEbooks.isEmpty) {
            return const Center(child: Text('Hakuna eBook bado.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: provider.myEbooks.length,
            itemBuilder: (_, i) {
              final e = provider.myEbooks[i];
              final ebookProvider = context.read<EbookProvider>();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () async {
                      final refreshed = await context.push<bool>(
                        '/trainer/ebooks/${e.id}',
                      );
                      if (refreshed == true && mounted) {
                        await ebookProvider.fetchMyEbooks();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 58,
                              height: 78,
                              color: const Color(0xFFF6EEE7),
                              child: e.coverImageUrl != null
                                  ? Image.network(
                                      e.coverImageUrl!,
                                      width: 58,
                                      height: 78,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.menu_book_outlined,
                                      color: Color(0xFFE87722),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e.title,
                                        style: AppTextStyles.h4.copyWith(
                                          color: const Color(0xFF1A0A00),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE87722)
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        e.status.isEmpty
                                            ? 'draft'
                                            : e.status.toUpperCase(),
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
                                          color: const Color(0xFFE87722),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Bei TZS ${_currency.format(e.priceInTzs)}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: const Color(0xFF4D3A2A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Wateja ${e.buyersCount}  •  Mauzo ${e.successfulPurchasesCount}  •  Mapato TZS ${_currency.format(e.totalRevenue)}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFF7A5C49),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') {
                                final refreshed = await context.push<bool>(
                                  '/trainer/ebooks/${e.id}/edit',
                                );
                                if (refreshed == true && mounted) {
                                  await ebookProvider.fetchMyEbooks();
                                }
                              } else if (v == 'delete') {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Futa eBook'),
                                    content: const Text(
                                      'Una uhakika unataka kufuta eBook hii?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Ghairi'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Futa'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await provider.deleteEbook(e.id);
                                }
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
