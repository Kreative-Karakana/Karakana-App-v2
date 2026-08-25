import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/karakana_wave_loader.dart';
import '../providers/ebook_provider.dart';

class EbookStoreScreen extends StatefulWidget {
  const EbookStoreScreen({super.key});

  @override
  State<EbookStoreScreen> createState() => _EbookStoreScreenState();
}

class _EbookStoreScreenState extends State<EbookStoreScreen> {
  static const _headerGradient = [
    Color(0xFF1A0A00),
    Color(0xFF3D1800),
    Color(0xFF7B3A10),
  ];
  final _currency = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EbookProvider>().fetchStore();
      context.read<EbookProvider>().fetchLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: _headerGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: const BackButton(color: Colors.white),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Duka la Vitabu',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline, color: Colors.white),
            onPressed: () => context.push('/zana/ebooks/library'),
          ),
        ],
      ),
      body: SafeArea(child: Consumer<EbookProvider>(
        builder: (_, provider, __) {
          if (provider.isLoadingStore) {
            return const Center(child: KarakanaWaveLoader());
          }
          if (provider.store.isEmpty) {
            return const Center(child: Text('Hakuna vitabu kwa sasa.'));
          }
          return GridView.builder(
            padding: AppSpacing.cardPadding,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm + AppSpacing.xs,
              mainAxisSpacing: AppSpacing.sm + AppSpacing.xs,
              childAspectRatio: 0.62,
            ),
            itemCount: provider.store.length,
            itemBuilder: (_, i) {
              final ebook = provider.store[i];
              final owned = provider.isOwned(ebook.id);
              return GestureDetector(
                onTap: () => context.push('/zana/ebooks/${ebook.id}'),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ebook.coverImageUrl != null &&
                                ebook.coverImageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: ebook.coverImageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (_, __) => Container(
                                  color: const Color(0xFFF5E6D8),
                                  alignment: Alignment.center,
                                  child: const KarakanaWaveLoader(size: 24),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: const Color(0xFFF5E6D8),
                                  child: const Center(
                                    child: Icon(Icons.menu_book_outlined),
                                  ),
                                ),
                              )
                            : Container(
                                color: const Color(0xFFF5E6D8),
                                child: const Center(
                                    child: Icon(Icons.menu_book_outlined)),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(
                            AppSpacing.sm + AppSpacing.xs / 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ebook.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h4,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(ebook.authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              ebook.isFree
                                  ? 'Bure'
                                  : 'TZS ${_currency.format(ebook.priceInTzs)}',
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () =>
                                    context.push('/zana/ebooks/${ebook.id}'),
                                child: Text(owned ? 'Soma' : 'Nunua'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      )),
    );
  }
}
