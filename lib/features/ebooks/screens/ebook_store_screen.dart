import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../widgets/common/karakana_wave_loader.dart';
import '../providers/ebook_provider.dart';

class EbookStoreScreen extends StatefulWidget {
  const EbookStoreScreen({super.key});

  @override
  State<EbookStoreScreen> createState() => _EbookStoreScreenState();
}

class _EbookStoreScreenState extends State<EbookStoreScreen> {
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
      appBar: AppBar(
        title: const Text('Duka la Vitabu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () => context.push('/zana/ebooks/library'),
          ),
        ],
      ),
      body: Consumer<EbookProvider>(
        builder: (_, provider, __) {
          if (provider.isLoadingStore) {
            return const Center(child: KarakanaWaveLoader());
          }
          if (provider.store.isEmpty) {
            return const Center(child: Text('Hakuna vitabu kwa sasa.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
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
                        child: ebook.coverImageUrl != null && ebook.coverImageUrl!.isNotEmpty
                            ? Image.network(ebook.coverImageUrl!, fit: BoxFit.cover, width: double.infinity)
                            : Container(
                                color: const Color(0xFFF5E6D8),
                                child: const Center(child: Icon(Icons.menu_book_outlined)),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ebook.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(ebook.authorName, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(ebook.isFree ? 'Bure' : 'TZS ${ebook.priceInTzs}'),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => context.push('/zana/ebooks/${ebook.id}'),
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
      ),
    );
  }
}
