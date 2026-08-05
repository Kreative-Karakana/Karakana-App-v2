import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/zana_model.dart';

class ZanaScreen extends StatefulWidget {
  const ZanaScreen({super.key});

  @override
  State<ZanaScreen> createState() => _ZanaScreenState();
}

class _ZanaScreenState extends State<ZanaScreen> {
  static const double _portraitHeaderHeight = 164;
  static const double _landscapeHeaderHeight = 136;
  static const double _maxContentWidth = 1040;
  static const double _minimumCardWidth = 190;
  static const double _cardHeight = 228;
  static const double _narrowCardHeight = 304;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final baseHeaderHeight =
        isLandscape ? _landscapeHeaderHeight : _portraitHeaderHeight;
    final expandedHeight = baseHeaderHeight + math.max(0, textScale - 1) * 96;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        key: const Key('zana-scroll-view'),
        controller: _scrollController,
        slivers: [
          _ZanaHeader(
            scrollController: _scrollController,
            expandedHeight: expandedHeight,
          ),
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final layout = _ZanaGridLayout.fromWidth(
                constraints.crossAxisExtent,
              );
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final extraTextHeight = math.max(0.0, textScale - 1) * 88;
              final baseCardHeight = constraints.crossAxisExtent < 360
                  ? _narrowCardHeight
                  : _cardHeight;

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  layout.horizontalInset,
                  AppSpacing.lg,
                  layout.horizontalInset,
                  0,
                ),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: layout.columnCount,
                        mainAxisSpacing: layout.gridSpacing,
                        crossAxisSpacing: layout.gridSpacing,
                        mainAxisExtent: baseCardHeight + extraTextHeight,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tool = ZanaData.tools[index];
                          return _ZanaToolCard(
                            key: Key('zana-card-${tool.id}'),
                            tool: tool,
                            onTap: () => context.push(tool.route),
                          );
                        },
                        childCount: ZanaData.tools.length,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZanaHeader extends StatelessWidget {
  final ScrollController scrollController;
  final double expandedHeight;

  const _ZanaHeader({
    required this.scrollController,
    required this.expandedHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 360;
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppColors.zanaPrimary,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleSpacing: AppSpacing.screenPadding.left,
      title: AnimatedBuilder(
        animation: scrollController,
        builder: (context, _) {
          final showTitle = scrollController.hasClients &&
              scrollController.offset > expandedHeight - kToolbarHeight - 12;
          return AnimatedOpacity(
            opacity: showTitle ? 1 : 0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: Text(
              'Zana',
              style: AppTextStyles.h3.copyWith(color: AppColors.textOnDark),
            ),
          );
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: DecoratedBox(
          decoration: BoxDecoration(color: AppColors.zanaPrimary),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -18,
                bottom: -24,
                child: Icon(
                  Icons.widgets_outlined,
                  size: 138,
                  color: AppColors.textOnDark.withValues(alpha: 0.055),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding.left,
                    AppSpacing.md,
                    isNarrow ? AppSpacing.xl : AppSpacing.xxxl + AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zana',
                        style: AppTextStyles.displayLarge.copyWith(
                          color: AppColors.textOnDark,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Zana rahisi na za kuaminika kwa ukuaji wa biashara yako.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textOnDark.withValues(alpha: 0.78),
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
    );
  }
}

class _ZanaToolCard extends StatelessWidget {
  final ZanaTool tool;
  final VoidCallback onTap;

  const _ZanaToolCard({
    super.key,
    required this.tool,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    final isPhoneWidth = MediaQuery.sizeOf(context).width < 600;
    final useCompactRecommendation =
        hasLargeText || MediaQuery.sizeOf(context).width < 360;
    final cardPadding = isPhoneWidth
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.md - AppSpacing.xs,
            vertical: AppSpacing.md,
          )
        : AppSpacing.cardPadding;

    return Semantics(
      button: true,
      label: '${tool.nameSwahili}. ${_semanticStatusLabel(tool.status)}. '
          '${tool.descriptionSwahili}',
      child: Material(
        key: Key('zana-material-${tool.id}'),
        color: colors.surface,
        elevation: tool.isRecommended ? 2 : 0,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLg),
          side: BorderSide(
            color: tool.isRecommended
                ? AppColors.primary.withValues(alpha: isDark ? 0.78 : 0.58)
                : colors.outlineVariant.withValues(alpha: isDark ? 0.72 : 0.8),
            width: tool.isRecommended ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.10),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: isDark ? 0.16 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                      child: Icon(
                        tool.icon,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    if (tool.isRecommended)
                      _ZanaRecommendationBadge(
                        compact: useCompactRecommendation,
                      )
                    else
                      Container(
                        key: Key('zana-arrow-${tool.id}'),
                        width: AppSpacing.xl,
                        height: AppSpacing.xl,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  tool.nameSwahili,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(
                  child: Text(
                    tool.descriptionSwahili,
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZanaRecommendationBadge extends StatelessWidget {
  final bool compact;

  const _ZanaRecommendationBadge({required this.compact});

  @override
  Widget build(BuildContext context) {
    if (!compact) {
      return Semantics(
        label: 'Imependekezwa',
        excludeSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 28),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Text(
            'Bora',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: 'Imependekezwa',
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.star_rounded,
          size: 16,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ZanaGridLayout {
  final int columnCount;
  final double horizontalInset;
  final double gridSpacing;

  const _ZanaGridLayout({
    required this.columnCount,
    required this.horizontalInset,
    required this.gridSpacing,
  });

  factory _ZanaGridLayout.fromWidth(double availableWidth) {
    final isLargeLayout = availableWidth >= 600;
    final horizontalInset = isLargeLayout ? AppSpacing.xl : AppSpacing.md;
    final gridSpacing = isLargeLayout ? AppSpacing.md : AppSpacing.sm;
    final contentWidth = math.min(
      availableWidth - (horizontalInset * 2),
      _ZanaScreenState._maxContentWidth,
    );
    final columns = (contentWidth / _ZanaScreenState._minimumCardWidth)
        .floor()
        .clamp(2, 4)
        .toInt();
    return _ZanaGridLayout(
      columnCount: columns,
      horizontalInset: math.max(
        horizontalInset,
        (availableWidth - _ZanaScreenState._maxContentWidth) / 2,
      ),
      gridSpacing: gridSpacing,
    );
  }
}

String _semanticStatusLabel(ZanaStatus status) {
  return switch (status) {
    ZanaStatus.live => 'Inapatikana sasa',
    ZanaStatus.beta => 'Toleo la majaribio',
    ZanaStatus.comingSoon => 'Inakuja hivi karibuni',
  };
}
