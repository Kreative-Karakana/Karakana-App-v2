import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final userName = auth.userFullName.isNotEmpty ? auth.userFullName : 'Mtumiaji wa Karakana';
        final userEmail = auth.userEmail.isNotEmpty ? auth.userEmail : 'Hakuna barua pepe';
        final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'K';

        return Scaffold(
          backgroundColor: const Color(0xFFFFF8F4),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: const Color(0xFF3B1A08),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => context.push('/profile/edit'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Akaunti',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B1A08), Color(0xFF6B2E0A)],
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
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.04),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFC4620A),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: auth.userAvatar != null
                                        ? CachedNetworkImage(
                                            imageUrl: auth.userAvatar!,
                                            width: 88,
                                            height: 88,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => _avatarFallback(initial),
                                          )
                                        : _avatarFallback(initial),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  userName,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userEmail,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC4620A).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFC4620A)),
                                  ),
                                  child: Text(
                                    auth.isTrainer ? 'Mwalimu' : 'Mwanafunzi',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE8A96A),
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
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildMenuGroup(
                        'Kujifunza Kwangu',
                        [
                          _buildMenuItem(
                            Icons.school_outlined,
                            const Color(0xFF2E7D32),
                            'Kozi Zangu',
                            subtitle: 'Kozi ulizojiandikisha',
                            onTap: () => context.push('/my-courses'),
                          ),
                          _buildMenuItem(
                            Icons.bookmark_outlined,
                            const Color(0xFFB71C1C),
                            'Vipendwa Vyangu',
                            onTap: () => context.push('/wishlist'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMenuGroup(
                        'Akaunti',
                        [
                          _buildMenuItem(
                            Icons.person_outlined,
                            const Color(0xFF1A2E5A),
                            'Hariri Wasifu',
                            onTap: () => context.push('/profile/edit'),
                          ),
                          _buildMenuItem(
                            Icons.payment_outlined,
                            const Color(0xFF2E7D32),
                            'Historia ya Malipo',
                            onTap: () => context.push('/payment/history'),
                          ),
                          if (auth.isTrainer)
                            _buildMenuItem(
                              Icons.account_balance_wallet_outlined,
                              const Color(0xFF6A1B9A),
                              'Mkoba Wangu',
                              onTap: () => context.push('/wallet'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMenuGroup(
                        'Msaada',
                        [
                          _buildMenuItem(
                            Icons.headset_mic_outlined,
                            const Color(0xFFC4620A),
                            'Msaada',
                            onTap: () => context.push('/support'),
                          ),
                          _buildMenuItem(
                            Icons.notifications_outlined,
                            const Color(0xFFE65100),
                            'Arifa',
                            onTap: () => context.push('/notifications'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (auth.isTrainer) ...[
                        _buildMenuGroup(
                          'Mwalimu',
                          [
                            _buildMenuItem(
                              Icons.dashboard_outlined,
                              const Color(0xFF3B1A08),
                              'Dashibodi ya Mwalimu',
                              onTap: () => context.push('/trainer/dashboard'),
                            ),
                            _buildMenuItem(
                              Icons.add_box_outlined,
                              const Color(0xFFC4620A),
                              'Unda Kozi Mpya',
                              onTap: () => context.push('/trainer/course-builder'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        GestureDetector(
                          onTap: () => context.push('/trainer/apply'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFC4620A), Color(0xFFE07030)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.school, color: Colors.white, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kuwa Mwalimu',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Fundisha na upate kipato',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(
                                  'Toka',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                                ),
                                content: Text(
                                  'Una uhakika unataka kutoka?',
                                  style: GoogleFonts.inter(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Hapana',
                                      style: GoogleFonts.inter(color: const Color(0xFF9E8070)),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.read<AuthProvider>().logout();
                                      context.go('/login');
                                    },
                                    child: Text(
                                      'Ndiyo, Toka',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFB71C1C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.logout, color: Color(0xFFB71C1C), size: 20),
                          label: Text(
                            'Toka',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB71C1C),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFFEBEE), width: 1.5),
                            backgroundColor: const Color(0xFFFFEBEE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _avatarFallback(String initial) {
    return Container(
      width: 88,
      height: 88,
      color: const Color(0xFFC4620A),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGroup(String title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0FC4620A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9E8070),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ...items.asMap().entries.map(
                (entry) => Column(
                  children: [
                    if (entry.key > 0)
                      const Divider(
                        height: 1,
                        color: Color(0xFFF0E4DA),
                        indent: 56,
                      ),
                    entry.value,
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    Color iconColor,
    String label, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF3B1A08),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF9E8070),
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFFE8D5C8),
        size: 18,
      ),
      onTap: onTap,
    );
  }
}
