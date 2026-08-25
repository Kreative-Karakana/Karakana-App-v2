import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/karakana_wave_loader.dart';
import '../providers/ebook_provider.dart';

class EbookLibraryScreen extends StatefulWidget {
  const EbookLibraryScreen({super.key});

  @override
  State<EbookLibraryScreen> createState() => _EbookLibraryScreenState();
}

class _EbookLibraryScreenState extends State<EbookLibraryScreen> {
  static const _headerGradient = [
    Color(0xFF1A0A00),
    Color(0xFF3D1800),
    Color(0xFF7B3A10),
  ];

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_library_outlined,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Maktaba ya Kidigitali',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFF8F2),
              const Color(0xFFFFEFE3),
              const Color(0xFFF7E5D8).withValues(alpha: 0.92),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Consumer<EbookProvider>(
            builder: (_, provider, __) {
              if (provider.isLoadingLibrary) {
                return const Center(child: KarakanaWaveLoader());
              }
              if (provider.library.isEmpty) {
                return Center(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Text(
                      'Bado hujanunua eBook yoyote.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: AppSpacing.cardPadding,
                itemCount: provider.library.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm + AppSpacing.xs / 2),
                itemBuilder: (_, i) {
                  final p = provider.library[i];
                  return Card(
                    elevation: 0,
                    color: Colors.white.withValues(alpha: 0.96),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      onTap: () => context.push(
                        '/zana/ebooks/read/${p.ebook.id}',
                        extra: {'ebookTitle': p.ebook.title},
                      ),
                      leading: p.ebook.coverImageUrl != null &&
                              p.ebook.coverImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.sm),
                              child: CachedNetworkImage(
                                imageUrl: p.ebook.coverImageUrl!,
                                width: 52,
                                height: 64,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const SizedBox(
                                  width: 52,
                                  height: 64,
                                  child: Center(
                                    child: KarakanaWaveLoader(size: 20),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => const SizedBox(
                                  width: 52,
                                  height: 64,
                                  child: Icon(Icons.menu_book_outlined),
                                ),
                              ),
                            )
                          : const Icon(Icons.menu_book_outlined),
                      title: Text(p.ebook.title),
                      subtitle: Text(
                        p.ebook.totalPages > 0
                            ? '${p.ebook.authorName} • ${p.ebook.totalPages} kurasa'
                            : p.ebook.authorName,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE87722).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFFE87722),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
