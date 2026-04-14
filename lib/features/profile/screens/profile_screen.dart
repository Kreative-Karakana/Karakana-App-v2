import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _expandedHeight = 210;
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Futa Akaunti',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Una uhakika unataka kufuta akaunti yako? Hatua hii haiwezi kurudishwa.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hapana',
              style: GoogleFonts.inter(color: const Color(0xFF9E8070)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Ndiyo, Futa',
              style: GoogleFonts.inter(
                color: const Color(0xFFB71C1C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await ApiClient().dio.delete('/api/v1/accounts/me/delete/');
      if (!context.mounted) return;
      await auth.logout();
      context.go('/login');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hitilafu. Jaribu tena.'),
          backgroundColor: Color(0xFFB71C1C),
        ),
      );
    }
  }

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
            controller: _scroll,
            slivers: [
              SliverAppBar(
                expandedHeight: _expandedHeight,
                pinned: true,
                backgroundColor: const Color(0xFF3B1A08),
                title: AnimatedBuilder(
                  animation: _scroll,
                  builder: (context, _) {
                    final show = _scroll.hasClients &&
                        _scroll.offset > (_expandedHeight - kToolbarHeight);
                    return AnimatedOpacity(
                      opacity: show ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        'Akaunti',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => context.push('/profile/edit'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2A0F04), Color(0xFF3B1A08), Color(0xFF6B2E0A)],
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
                          left: -20,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFC4620A).withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 30,
                          right: 16,
                          child: Icon(
                            Icons.account_circle_outlined,
                            size: 100,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Akaunti',
                                  style: GoogleFonts.poppins(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Wasifu na Mipangilio Yako',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.55),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _headerChip(Icons.person_outline, 'Wasifu'),
                                    const SizedBox(width: 8),
                                    _headerChip(Icons.school_outlined, 'Kozi Zangu'),
                                    const SizedBox(width: 8),
                                    _headerChip(Icons.headset_mic_outlined, 'Msaada'),
                                  ],
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
              // Profile card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC4620A).withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFC4620A),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: auth.userAvatar != null
                                ? CachedNetworkImage(
                                    imageUrl: auth.userAvatar!,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => _avatarFallback(initial),
                                  )
                                : _avatarFallback(initial),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A0A00),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF9E8070),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC4620A).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFC4620A).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  auth.isTrainer ? 'Mwalimu' : 'Mwanafunzi',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFC4620A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => _deleteAccount(context, auth),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFF9E8070),
                            size: 18,
                          ),
                          label: Text(
                            'Futa Akaunti',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9E8070),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _headerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
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
