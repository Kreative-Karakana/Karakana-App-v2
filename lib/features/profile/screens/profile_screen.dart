import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.userFullName.isEmpty ? 'User' : auth.userFullName;
    final initials = _initials(name);
    final role = auth.user?['role']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ───────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.dark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.dark, AppColors.primary],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.lightOrange,
                      backgroundImage:
                          auth.userAvatar != null &&
                              auth.userAvatar!.isNotEmpty
                          ? CachedNetworkImageProvider(auth.userAvatar!)
                          : null,
                      child:
                          (auth.userAvatar == null || auth.userAvatar!.isEmpty)
                          ? Text(
                              initials,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      auth.userEmail,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Menu items ────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _MenuItem(
                  icon: Icons.person_outline,
                  label: 'Edit Profile',
                  onTap: () => context.push('/profile/edit'),
                ),
                const Divider(height: 1, indent: 72),
                _MenuItem(
                  icon: Icons.school_outlined,
                  label: 'My Courses',
                  onTap: () => context.push('/enrolled-courses'),
                ),
                const Divider(height: 1, indent: 72),
                _MenuItem(
                  icon: Icons.favorite_outline,
                  label: 'Wishlist',
                  onTap: () => context.push('/wishlist'),
                ),
                const Divider(height: 1, indent: 72),
                _MenuItem(
                  icon: Icons.payment_outlined,
                  label: 'Payment History',
                  onTap: () => context.push('/payment-history'),
                ),
                if (role.contains('trainer')) ...[
                  const Divider(height: 1, indent: 72),
                  _MenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'My Wallet',
                    onTap: () => context.push('/wallet'),
                  ),
                ],
                const Divider(height: 1, indent: 72),
                _MenuItem(
                  icon: Icons.support_agent_outlined,
                  label: 'Support',
                  onTap: () => context.push('/support'),
                ),
                const Divider(height: 1, indent: 72),
                _MenuItem(
                  icon: Icons.info_outline,
                  label: 'About',
                  onTap: () => _showAboutDialog(context),
                ),
                const Divider(height: 1, indent: 72),
                _MenuItem(
                  icon: Icons.logout_outlined,
                  label: 'Logout',
                  isDestructive: true,
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('About Karakana'),
        content: const Text(
          'Version 1.0.0\n\nKarakana is an entrepreneurship training platform by Kreative Karakana, connecting learners across Tanzania.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.primary;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.lightOrange,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.dark,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
    );
  }
}
