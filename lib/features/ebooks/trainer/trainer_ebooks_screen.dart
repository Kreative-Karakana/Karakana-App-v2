import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../widgets/common/karakana_wave_loader.dart';
import '../providers/ebook_provider.dart';

class TrainerEbooksScreen extends StatefulWidget {
  const TrainerEbooksScreen({super.key});

  @override
  State<TrainerEbooksScreen> createState() => _TrainerEbooksScreenState();
}

class _TrainerEbooksScreenState extends State<TrainerEbooksScreen> {
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
            itemCount: provider.myEbooks.length,
            itemBuilder: (_, i) {
              final e = provider.myEbooks[i];
              return ListTile(
                leading: e.coverImageUrl != null
                    ? Image.network(e.coverImageUrl!, width: 48, height: 48, fit: BoxFit.cover)
                    : const Icon(Icons.menu_book_outlined),
                title: Text(e.title),
                subtitle: Text('TZS ${e.priceInTzs}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      context.push('/trainer/ebooks/${e.id}/edit');
                    } else if (v == 'delete') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Futa eBook'),
                          content: const Text('Una uhakika unataka kufuta eBook hii?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ghairi')),
                            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Futa')),
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
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
