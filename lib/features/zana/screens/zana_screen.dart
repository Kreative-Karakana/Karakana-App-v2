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
  static const double _portraitHeaderHeight = 170;
  static const double _landscapeHeaderHeight = 150;
  static const double _maxContentWidth = 1040;
  static const double _minimumCardWidth = 184;
  static const double _cardHeight = 230;
  static const double _narrowCardHeight = 286;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final textScale = mediaQuery.textScaler.scale(1);
    final baseHeaderHeight =
        isLandscape ? _landscapeHeaderHeight : _portraitHeaderHeight;
    final expandedHeight = baseHeaderHeight + math.max(0, textScale - 1) * 96;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        key: const Key('zana-scroll-view'),
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _ZanaHeader(
            scrollController: _scrollController,
            expandedHeight: expandedHeight,
          ),
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final layout =
                  _ZanaGridLayout.fromWidth(constraints.crossAxisExtent);
              final extraTextHeight = math.max(0.0, textScale - 1) * 104;
              final baseCardHeight = constraints.crossAxisExtent < 360
                  ? _narrowCardHeight
                  : _cardHeight;

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  layout.horizontalInset,
                  AppSpacing.md,
                  layout.horizontalInset,
                  0,
                ),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Text(
                        'Zana Zinazopatikana',
                        style: AppTextStyles.h3.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.md),
                    ),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.zanaGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned(
                top: -54,
                right: -42,
                child: _HeaderOrb(size: 190, opacity: 0.05),
              ),
              Positioned(
                right: 14,
                top: 28,
                child: Icon(
                  Icons.business_center_outlined,
                  size: 112,
                  color: AppColors.textOnDark.withValues(alpha: 0.05),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding.left,
                    AppSpacing.sm,
                    isNarrow ? AppSpacing.xl : 116,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zana',
                        style: AppTextStyles.displayLarge.copyWith(
                          color: AppColors.textOnDark,
                          fontSize: isNarrow ? 36 : 42,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Zana za Biashara kwa Ujasiriamali',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textOnDark.withValues(alpha: 0.72),
                          height: 1.3,
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

class _HeaderOrb extends StatelessWidget {
  final double size;
  final double opacity;

  const _HeaderOrb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.textOnDark.withValues(alpha: opacity),
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
    final isLive = tool.status == ZanaStatus.live;
    final isNarrow = MediaQuery.sizeOf(context).width < 360;
    final cardPadding = isNarrow
        ? const EdgeInsets.all(AppSpacing.sm)
        : const EdgeInsets.all(AppSpacing.md);

    return Semantics(
      button: true,
      label: '${tool.nameSwahili}. ${_semanticStatusLabel(tool.status)}. '
          '${tool.descriptionSwahili}',
      child: Material(
        key: Key('zana-material-${tool.id}'),
        elevation: 4,
        shadowColor: AppColors.zanaGradient.first.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.zanaGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned(
                top: -22,
                right: -22,
                child: _HeaderOrb(size: 86, opacity: 0.06),
              ),
              InkWell(
                onTap: onTap,
                splashColor: AppColors.textOnDark.withValues(alpha: 0.10),
                highlightColor: AppColors.textOnDark.withValues(alpha: 0.06),
                child: Padding(
                  padding: cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.textOnDark.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.input),
                        ),
                        child: Icon(
                          tool.icon,
                          color: AppColors.textOnDark,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        tool.nameSwahili,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textOnDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          tool.descriptionSwahili,
                          maxLines: 8,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textOnDark.withValues(alpha: 0.72),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (isLive)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Fungua',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textOnDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                              color: AppColors.textOnDark,
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textOnDark.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                            border: Border.all(
                              color:
                                  AppColors.textOnDark.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Text(
                            'Niarifu',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textOnDark,
                              fontWeight: FontWeight.w700,
                            ),
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
