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
    final avatar = auth.userAvatar;
    final hasAvatar = avatar != null && avatar.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient header ──────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Background gradient
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3B1A08), Color(0xFF8B3A0F)],
                    ),
                  ),
                ),

                // Decorative circles
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 40,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),

                // Header content
                SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 220,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Avatar with white border
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: AppColors.lightOrange,
                            backgroundImage: hasAvatar
                                ? CachedNetworkImageProvider(avatar)
                                : null,
                            child: hasAvatar
                                ? null
                                : Text(
                                    initials,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.userEmail,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Stats pills
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatPill(label: 'Member'),
                            if (role.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              _StatPill(
                                label: role[0].toUpperCase() + role.substring(1),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Menu card (overlaps header by 20px) ─
            Container(
              margin: const EdgeInsets.fromLTRB(16, -20, 16, 0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.person_outline,
                      iconBg: const Color(0xFFE3F2FD),
                      iconColor: Colors.blue.shade700,
                      label: 'Edit Profile',
                      onTap: () => context.push('/profile/edit'),
                    ),
                    const _ItemDivider(),
                    _MenuItem(
                      icon: Icons.school_outlined,
                      iconBg: const Color(0xFFE8F5E9),
                      iconColor: Colors.green.shade700,
                      label: 'My Courses',
                      onTap: () => context.push('/enrolled-courses'),
                    ),
                    const _ItemDivider(),
                    _MenuItem(
                      icon: Icons.favorite_outline,
                      iconBg: const Color(0xFFFFEBEE),
                      iconColor: Colors.red.shade600,
                      label: 'Wishlist',
                      onTap: () => context.push('/wishlist'),
                    ),
                    const _ItemDivider(),
                    _MenuItem(
                      icon: Icons.payment_outlined,
                      iconBg: const Color(0xFFE8F5E9),
                      iconColor: Colors.green.shade600,
                      label: 'Payment History',
                      onTap: () => context.push('/payment-history'),
                    ),
                    if (role.contains('trainer')) ...[
                      const _ItemDivider(),
                      _MenuItem(
                        icon: Icons.account_balance_wallet_outlined,
                        iconBg: const Color(0xFFF3E5F5),
                        iconColor: Colors.purple.shade600,
                        label: 'My Wallet',
                        onTap: () => context.push('/wallet'),
                      ),
                    ],
                    const _ItemDivider(),
                    _MenuItem(
                      icon: Icons.support_agent_outlined,
                      iconBg: const Color(0xFFFFF3E0),
                      iconColor: Colors.orange.shade700,
                      label: 'Support',
                      onTap: () => context.push('/support'),
                    ),
                    const _ItemDivider(),
                    _MenuItem(
                      icon: Icons.info_outline,
                      iconBg: const Color(0xFFF5F5F5),
                      iconColor: Colors.grey.shade600,
                      label: 'About',
                      onTap: () => _showAboutDialog(context),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _MenuItem(
                      icon: Icons.logout_outlined,
                      iconBg: const Color(0xFFFFEBEE),
                      iconColor: AppColors.error,
                      label: 'Logout',
                      labelColor: AppColors.error,
                      onTap: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
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

// ─────────────────────────────────────────────
// Stat pill
// ─────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Menu item
// ─────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? AppColors.dark,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.grey,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Divider between menu items
// ─────────────────────────────────────────────

class _ItemDivider extends StatelessWidget {
  const _ItemDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 72, endIndent: 16);
  }
}
