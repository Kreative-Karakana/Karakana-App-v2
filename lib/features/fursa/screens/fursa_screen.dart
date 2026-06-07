import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/karakana_wave_loader.dart';
import '../models/fursa_item.dart';
import '../providers/fursa_provider.dart';

class FursaScreen extends StatefulWidget {
  const FursaScreen({super.key});

  @override
  State<FursaScreen> createState() => _FursaScreenState();
}

class _FursaScreenState extends State<FursaScreen> {
  static const double _expandedHeight = 170;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';
  String _selectedCategory = 'Yote';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FursaProvider>().loadItems();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  List<FursaItem> _filterItems(List<FursaItem> items) {
    return items.where((item) {
      final matchesCategory = _selectedCategory == 'Yote' ||
          item.category.toLowerCase() == _selectedCategory.toLowerCase();
      if (!matchesCategory) return false;

      if (_query.isEmpty) return true;
      final haystack = [
        item.title,
        item.subtitle,
        item.deadlineText,
        item.summary,
        item.sourceLabel,
        item.category,
      ].join(' ').toLowerCase();
      return haystack.contains(_query);
    }).toList();
  }

  FursaItem? _nearestUpcomingDeadlineItem(List<FursaItem> items) {
    final today = DateUtils.dateOnly(DateTime.now());
    final upcoming = items
        .map((item) => MapEntry(item, _parseDeadline(item.deadlineText)))
        .where((entry) => entry.value != null && !entry.value!.isBefore(today))
        .toList()
      ..sort((a, b) => a.value!.compareTo(b.value!));

    return upcoming.isEmpty ? null : upcoming.first.key;
  }

  DateTime? _parseDeadline(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final match = RegExp(
      r'^(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]+)\s+(\d{4})$',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = _monthNumber(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;

    return DateTime(year, month, day);
  }

  int? _monthNumber(String month) {
    switch (month.toLowerCase()) {
      case 'january':
        return 1;
      case 'february':
        return 2;
      case 'march':
        return 3;
      case 'april':
        return 4;
      case 'may':
        return 5;
      case 'june':
        return 6;
      case 'july':
        return 7;
      case 'august':
        return 8;
      case 'september':
        return 9;
      case 'october':
        return 10;
      case 'november':
        return 11;
      case 'december':
        return 12;
    }
    return null;
  }

  Future<void> _openItem(FursaItem item) async {
    final uri = Uri.tryParse(item.sourceUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2ED),
      body: SafeArea(
        top: false,
        child: Consumer<FursaProvider>(
          builder: (context, provider, _) {
            final filteredItems = _filterItems(provider.items);
            final upcomingDeadlineItem =
                _nearestUpcomingDeadlineItem(filteredItems);
            final categories = <String>{
              'Yote',
              ...provider.items
                  .map((item) => item.category.trim())
                  .where((item) => item.isNotEmpty),
            }.toList();

            return RefreshIndicator(
              onRefresh: provider.loadItems,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: _expandedHeight,
                    pinned: true,
                    backgroundColor: const Color(0xFF3D1800),
                    title: AnimatedBuilder(
                      animation: _scrollController,
                      builder: (context, _) {
                        final show = _scrollController.hasClients &&
                            _scrollController.offset >
                                (_expandedHeight - kToolbarHeight);
                        return AnimatedOpacity(
                          opacity: show ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            'Fursa',
                            style: AppTextStyles.h3.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF1A0A00),
                              Color(0xFF3D1800),
                              Color(0xFF7B3A10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -40,
                              right: -40,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.04),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -30,
                              left: -30,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFE87722)
                                      .withValues(alpha: 0.18),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 28,
                              right: 18,
                              child: Icon(
                                Icons.campaign_outlined,
                                size: 108,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            SafeArea(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 20, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fursa',
                                      style:
                                          AppTextStyles.displayMedium.copyWith(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Nafasi, matangazo, na maudhui ya nje yanayoweza kukuza biashara yako.',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.78),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1A0A00)
                                        .withValues(alpha: 0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Tafuta fursa...',
                                  prefixIcon: Icon(Icons.search),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE87722),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.tune,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 54,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, index) {
                          final category = categories[index];
                          final isSelected = category == _selectedCategory;
                          return ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => _selectedCategory = category);
                            },
                            labelStyle: AppTextStyles.labelLarge.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF3A3A3A),
                            ),
                            selectedColor: const Color(0xFFE87722),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide.none,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (provider.isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: KarakanaWaveLoader()),
                    )
                  else if (provider.errorMessage != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            provider.errorMessage!,
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    if (upcomingDeadlineItem != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                          child: _FeaturedFursaCard(
                            item: upcomingDeadlineItem,
                            onTap: () => _openItem(upcomingDeadlineItem),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fursa Mpya',
                              style: AppTextStyles.h2.copyWith(
                                color: const Color(0xFF1E1E1E),
                              ),
                            ),
                            Text(
                              '${filteredItems.length} items',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: const Color(0xFF7A7A7A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (filteredItems.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Hakuna fursa zinazolingana na utafutaji wako kwa sasa.',
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverList.separated(
                          itemCount: filteredItems.length,
                          itemBuilder: (_, index) {
                            final item = filteredItems[index];
                            return _FursaListCard(
                              item: item,
                              onTap: () => _openItem(item),
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeaturedFursaCard extends StatelessWidget {
  final FursaItem item;
  final VoidCallback onTap;

  const _FeaturedFursaCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1A0A00),
              Color(0xFF3D1800),
              Color(0xFF7B3A10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -42,
              right: -36,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -34,
              left: -28,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE87722).withValues(alpha: 0.18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.badgeText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.badgeText,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.1,
                    ),
                  ),
                  if (item.summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                  if (item.deadlineText.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      'Deadline: ${item.deadlineText}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    height: 38,
                    child: FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE87722),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child:
                          Text(item.ctaText.isEmpty ? 'Fungua' : item.ctaText),
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

class _FursaListCard extends StatelessWidget {
  final FursaItem item;
  final VoidCallback onTap;

  const _FursaListCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (item.badgeText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EEE8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.badgeText,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFFE87722),
                        ),
                      ),
                    ),
                  if (item.amountText.isNotEmpty) ...[
                    const Spacer(),
                    Text(
                      item.amountText,
                      style: AppTextStyles.h4.copyWith(
                        color: const Color(0xFFE87722),
                      ),
                    ),
                  ],
                ],
              ),
              if (item.deadlineText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.event_available_rounded,
                      size: 15,
                      color: Color(0xFFE87722),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Deadline: ${item.deadlineText}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: const Color(0xFFE87722),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h3.copyWith(
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              if (item.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF8A8A8A),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                item.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF636363),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: Color(0xFF7A7A7A),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.sourceLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF7A7A7A),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
