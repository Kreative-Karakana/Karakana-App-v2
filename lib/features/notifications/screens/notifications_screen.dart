import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';

enum _NotificationFilter {
  all('Zote'),
  unread('Mpya'),
  read('Zilizosomwa');

  const _NotificationFilter(this.label);

  final String label;
}

enum _NotificationCategory {
  course,
  payment,
  trainer,
  support,
  certificate,
  success,
  error,
  update,
  general,
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotificationFilter _selectedFilter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isTrainer = context.read<AuthProvider>().isTrainer;
      context
          .read<NotificationProvider>()
          .loadNotifications(isTrainer: isTrainer);
    });
  }

  List<NotificationModel> _visibleNotifications(
    List<NotificationModel> notifications,
  ) {
    switch (_selectedFilter) {
      case _NotificationFilter.all:
        return notifications;
      case _NotificationFilter.unread:
        return notifications.where((item) => !item.isRead).toList();
      case _NotificationFilter.read:
        return notifications.where((item) => item.isRead).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NotificationProvider, AuthProvider>(
      builder: (context, provider, auth, _) {
        final visibleNotifications =
            _visibleNotifications(provider.notifications);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  provider.loadNotifications(isTrainer: auth.isTrainer),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _NotificationsHeader(
                      isTrainer: auth.isTrainer,
                      unreadCount: provider.unreadCount,
                      totalCount: provider.notifications.length,
                      canMarkAllRead: provider.unreadCount > 0,
                      onBack: _handleBack,
                      onMarkAllRead: provider.markAllRead,
                    ),
                  ),
                  if (provider.isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: KarakanaWaveLoader(color: AppColors.primary),
                      ),
                    )
                  else if (provider.errorMessage != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NotificationsStateView(
                        icon: Icons.cloud_off_rounded,
                        title: 'Imeshindikana kupakia arifa',
                        message: provider.errorMessage ??
                            'Tafadhali jaribu tena baada ya muda mfupi.',
                        actionLabel: 'Jaribu Tena',
                        onAction: () => provider.loadNotifications(
                          isTrainer: auth.isTrainer,
                        ),
                      ),
                    )
                  else if (provider.notifications.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NotificationsStateView(
                        icon: Icons.notifications_none_rounded,
                        title: 'Hakuna arifa bado',
                        message: auth.isTrainer
                            ? 'Arifa za kozi, wanafunzi, mapato na akaunti ya mkufunzi zitaonekana hapa.'
                            : 'Arifa za kozi, malipo, msaada na akaunti yako zitaonekana hapa.',
                        actionLabel: 'Onyesha Upya',
                        onAction: () => provider.loadNotifications(
                          isTrainer: auth.isTrainer,
                        ),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: _NotificationFilters(
                        selectedFilter: _selectedFilter,
                        onChanged: (filter) {
                          setState(() => _selectedFilter = filter);
                        },
                      ),
                    ),
                    if (visibleNotifications.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _NotificationsStateView(
                          icon: Icons.mark_email_read_outlined,
                          title: 'Hakuna arifa hapa',
                          message:
                              'Badili kichujio ili kuona arifa nyingine kwenye akaunti hii.',
                          actionLabel: 'Onyesha Zote',
                          onAction: () {
                            setState(
                              () => _selectedFilter = _NotificationFilter.all,
                            );
                          },
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        sliver: SliverList.separated(
                          itemCount: visibleNotifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (_, index) {
                            final notification = visibleNotifications[index];
                            return _NotificationCard(
                              notification: notification,
                              timeAgo: _timeAgo(notification.createdAt),
                              category: _categoryFor(notification),
                              onTap: () => _openNotification(notification),
                            );
                          },
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _openNotification(NotificationModel notification) {
    context.read<NotificationProvider>().markRead(notification.id);
    final route = _resolveRoute(notification);
    if (route != null && route.isNotEmpty) {
      context.push(route);
    }
  }

  _NotificationCategory _categoryFor(NotificationModel notification) {
    final text = [
      notification.type,
      notification.title,
      notification.message,
      notification.route ?? '',
    ].join(' ').toLowerCase();

    if (text.contains('payment') ||
        text.contains('malipo') ||
        text.contains('wallet') ||
        text.contains('mkoba')) {
      return _NotificationCategory.payment;
    }
    if (text.contains('course') ||
        text.contains('kozi') ||
        text.contains('lesson')) {
      return _NotificationCategory.course;
    }
    if (text.contains('trainer') ||
        text.contains('mkufunzi') ||
        text.contains('/trainer')) {
      return _NotificationCategory.trainer;
    }
    if (text.contains('support') ||
        text.contains('msaada') ||
        text.contains('ticket')) {
      return _NotificationCategory.support;
    }
    if (text.contains('certificate') ||
        text.contains('cheti') ||
        text.contains('vyeti')) {
      return _NotificationCategory.certificate;
    }
    if (text.contains('success') ||
        text.contains('fanikiwa') ||
        text.contains('approved') ||
        text.contains('kubaliwa')) {
      return _NotificationCategory.success;
    }
    if (text.contains('error') ||
        text.contains('fail') ||
        text.contains('kataliwa') ||
        text.contains('shindikana')) {
      return _NotificationCategory.error;
    }
    if (text.contains('update') ||
        text.contains('status') ||
        text.contains('taarifa')) {
      return _NotificationCategory.update;
    }
    return _NotificationCategory.general;
  }

  String? _resolveRoute(NotificationModel notification) {
    final route = notification.route;
    if (route != null && route.isNotEmpty) return route;

    switch (_categoryFor(notification)) {
      case _NotificationCategory.course:
        return '/my-courses';
      case _NotificationCategory.payment:
        return '/payment/history';
      case _NotificationCategory.trainer:
        return '/trainer/dashboard';
      case _NotificationCategory.support:
        return '/support';
      case _NotificationCategory.certificate:
        return '/trainer/dashboard';
      case _NotificationCategory.success:
      case _NotificationCategory.error:
      case _NotificationCategory.update:
      case _NotificationCategory.general:
        return null;
    }
  }

  String _timeAgo(String createdAt) {
    try {
      final date = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays} siku zilizopita';
      if (diff.inHours > 0) return '${diff.inHours} saa zilizopita';
      if (diff.inMinutes > 0) return '${diff.inMinutes} dakika zilizopita';
      return 'Sasa hivi';
    } catch (_) {
      return createdAt;
    }
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.isTrainer,
    required this.unreadCount,
    required this.totalCount,
    required this.canMarkAllRead,
    required this.onBack,
    required this.onMarkAllRead,
  });

  final bool isTrainer;
  final int unreadCount;
  final int totalCount;
  final bool canMarkAllRead;
  final VoidCallback onBack;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HeaderActionButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBack,
              ),
              const Spacer(),
              Text(
                'Arifa',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _HeaderActionButton(
                icon: Icons.done_all_rounded,
                onTap: canMarkAllRead ? onMarkAllRead : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.cardGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.cardLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RoleBadge(isTrainer: isTrainer),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        unreadCount == 0
                            ? 'Umesoma arifa zote'
                            : '$unreadCount arifa mpya',
                        style: AppTextStyles.h1.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '$totalCount jumla kwenye akaunti hii',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isTrainer});

  final bool isTrainer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        isTrainer ? 'Akaunti ya Mkufunzi' : 'Akaunti ya Mwanafunzi',
        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            color: enabled ? AppColors.textPrimary : AppColors.textHint,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _NotificationFilters extends StatelessWidget {
  const _NotificationFilters({
    required this.selectedFilter,
    required this.onChanged,
  });

  final _NotificationFilter selectedFilter;
  final ValueChanged<_NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: _NotificationFilter.values.map((filter) {
          final selected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              selected: selected,
              label: Text(filter.label),
              onSelected: (_) => onChanged(filter),
              labelStyle: AppTextStyles.labelMedium.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              selectedColor: AppColors.primaryDark,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? AppColors.primaryDark : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.timeAgo,
    required this.category,
    required this.onTap,
  });

  final NotificationModel notification;
  final String timeAgo;
  final _NotificationCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _categoryStyle(category, notification.isRead);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.border.withValues(alpha: 0.7)
                  : AppColors.primary.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: style.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: style.border),
                ),
                child: Icon(style.icon, color: style.color, size: 21),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          timeAgo,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    if (!notification.isRead) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Mpya',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsStateView extends StatelessWidget {
  const _NotificationsStateView({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.cardLg),
            ),
            child: Icon(icon, color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              actionLabel,
              style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCategoryStyle {
  const _NotificationCategoryStyle({
    required this.color,
    required this.background,
    required this.border,
    required this.icon,
  });

  final Color color;
  final Color background;
  final Color border;
  final IconData icon;
}

_NotificationCategoryStyle _categoryStyle(
  _NotificationCategory category,
  bool isRead,
) {
  final opacity = isRead ? 0.08 : 0.14;

  switch (category) {
    case _NotificationCategory.course:
      return _style(
        AppColors.primary,
        opacity,
        Icons.school_outlined,
      );
    case _NotificationCategory.payment:
      return _style(
        const Color(0xFF0E9F6E),
        opacity,
        Icons.account_balance_wallet_outlined,
      );
    case _NotificationCategory.trainer:
      return _style(
        const Color(0xFF7B3A10),
        opacity,
        Icons.person_outline_rounded,
      );
    case _NotificationCategory.support:
      return _style(
        const Color(0xFF2563EB),
        opacity,
        Icons.support_agent_outlined,
      );
    case _NotificationCategory.certificate:
      return _style(
        const Color(0xFFB86A00),
        opacity,
        Icons.workspace_premium_outlined,
      );
    case _NotificationCategory.success:
      return _style(
        const Color(0xFF0E9F6E),
        opacity,
        Icons.check_circle_outline_rounded,
      );
    case _NotificationCategory.error:
      return _style(
        AppColors.error,
        opacity,
        Icons.error_outline_rounded,
      );
    case _NotificationCategory.update:
      return _style(
        const Color(0xFF2563EB),
        opacity,
        Icons.info_outline_rounded,
      );
    case _NotificationCategory.general:
      return _style(
        AppColors.primary,
        opacity,
        Icons.notifications_outlined,
      );
  }
}

_NotificationCategoryStyle _style(
  Color color,
  double opacity,
  IconData icon,
) {
  return _NotificationCategoryStyle(
    color: color,
    background: color.withValues(alpha: opacity),
    border: color.withValues(alpha: opacity + 0.06),
    icon: icon,
  );
}
