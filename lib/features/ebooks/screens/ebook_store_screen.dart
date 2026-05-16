import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3D1800), Color(0xFF7B3A10), Color(0xFFE87722)],
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
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
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
