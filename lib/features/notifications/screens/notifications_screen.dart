import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Arifa',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, provider, __) => provider.notifications.isNotEmpty
                ? TextButton(
                    onPressed: provider.markAllRead,
                    child: Text(
                      'Soma Zote',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(child: Consumer<NotificationProvider>(
        builder: (_, provider, __) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          if (provider.isLoading) {
            return const Center(
              child: KarakanaWaveLoader(color: Color(0xFFE87722)),
            );
          }
          if (provider.notifications.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.notifications.length,
            itemBuilder: (_, index) {
              final notif = provider.notifications[index];
              final isUnread = !notif.isRead;
              return Container(
                color: isUnread
                    ? (isDark
                        ? const Color(0xFF2A1A0A).withValues(alpha: 0.5)
                        : const Color(0xFFF5E6D8).withValues(alpha: 0.5))
                    : Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isUnread
                          ? const Color(0xFFE87722).withValues(alpha: 0.14)
                          : const Color(0xFF9E8070).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUnread
                            ? const Color(0xFFE87722).withValues(alpha: 0.3)
                            : const Color(0xFFBDA99C).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      _getNotificationIcon(notif.type),
                      color: isUnread
                          ? const Color(0xFFE87722)
                          : const Color(0xFF9E8070),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    notif.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                      color: Theme.of(context).textTheme.bodyLarge?.color ??
                          const Color(0xFF1A0A00),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notif.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: const Color(0xFF9E8070),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _timeAgo(notif.createdAt),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: const Color(0xFFBDA99C),
                        ),
                      ),
                    ],
                  ),
                  trailing: isUnread
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE87722),
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () {
                    context.read<NotificationProvider>().markRead(notif.id);
                    final route = _resolveRoute(notif);
                    if (route != null && route.isNotEmpty) {
                      context.push(route);
                    }
                  },
                ),
              );
            },
          );
        },
      )),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'course':
        return Icons.school_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'trainer':
        return Icons.person_outlined;
      case 'support':
        return Icons.support_agent_outlined;
      case 'certificate':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String? _resolveRoute(dynamic notif) {
    final route = notif.route as String?;
    if (route != null && route.isNotEmpty) return route;
    switch (notif.type as String) {
      case 'course':
        return '/my-courses';
      case 'payment':
        return '/payment/history';
      case 'trainer':
        return '/trainer/dashboard';
      case 'support':
        return '/support';
      default:
        return null;
    }
  }

  String _timeAgo(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays} siku zilizopita';
      if (diff.inHours > 0) return '${diff.inHours} saa zilizopita';
      if (diff.inMinutes > 0) return '${diff.inMinutes} dakika zilizopita';
      return 'Sasa hivi';
    } catch (_) {
      return createdAt;
    }
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: Color(0xFFE87722),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Hakuna Arifa Bado',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color ??
                  const Color(0xFF1A0A00),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Arifa zako zitaonekana hapa.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF9E8070),
            ),
          ),
        ],
      ),
    );
  }
}
