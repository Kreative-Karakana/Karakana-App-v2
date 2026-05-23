import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../widgets/common/karakana_wave_loader.dart';
import '../providers/ebook_provider.dart';

class EbookLibraryScreen extends StatefulWidget {
  const EbookLibraryScreen({super.key});

  @override
  State<EbookLibraryScreen> createState() => _EbookLibraryScreenState();
}

class _EbookLibraryScreenState extends State<EbookLibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EbookProvider>().fetchLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maktaba Yangu')),
      body: SafeArea(child: Consumer<EbookProvider>(
        builder: (_, provider, __) {
          if (provider.isLoadingLibrary) {
            return const Center(child: KarakanaWaveLoader());
          }
          if (provider.library.isEmpty) {
            return const Center(child: Text('Bado hujanunua eBook yoyote.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.library.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final p = provider.library[i];
              return Card(
                child: ListTile(
                  onTap: () => context.push(
                    '/zana/ebooks/read/${p.ebook.id}',
                    extra: {'ebookTitle': p.ebook.title},
                  ),
                  leading: p.ebook.coverImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            p.ebook.coverImageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.menu_book_outlined),
                  title: Text(p.ebook.title),
                  subtitle: Text('Ref: ${p.externalId}'),
                  trailing: const Icon(Icons.lock_outline),
                ),
              );
            },
          );
        },
      )),
    );
  }
}
