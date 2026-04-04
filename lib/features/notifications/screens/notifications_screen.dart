import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B1A08),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Arifa',
          style: GoogleFonts.poppins(
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
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFC4620A)),
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
                    ? const Color(0xFFF5E6D8).withValues(alpha: 0.5)
                    : Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isUnread
                            ? const [Color(0xFFC4620A), Color(0xFFE07030)]
                            : const [Color(0xFFBDA99C), Color(0xFF9E8070)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notif.type),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    notif.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          isUnread ? FontWeight.w600 : FontWeight.w400,
                      color: const Color(0xFF3B1A08),
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
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF9E8070),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _timeAgo(notif.createdAt),
                        style: GoogleFonts.inter(
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
                            color: Color(0xFFC4620A),
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () {
                    if (notif.route != null && notif.route!.isNotEmpty) {
                      context.push(notif.route!);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
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
      default:
        return Icons.notifications_outlined;
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFF5E6D8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: Color(0xFFC4620A),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Hakuna Arifa Bado',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A0A00),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Arifa zako zitaonekana hapa.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF9E8070),
            ),
          ),
        ],
      ),
    );
  }
}
