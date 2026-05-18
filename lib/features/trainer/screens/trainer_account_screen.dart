import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/secure_storage.dart';
import '../../../widgets/common/top_popup.dart';
import '../../auth/providers/auth_provider.dart';

class TrainerAccountScreen extends StatefulWidget {
  const TrainerAccountScreen({super.key});

  @override
  State<TrainerAccountScreen> createState() => _TrainerAccountScreenState();
}

class _TrainerAccountScreenState extends State<TrainerAccountScreen> {
  static const double _expandedHeight = 120;
  final ScrollController _scroll = ScrollController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _biometricBusy = false;
  String _biometricLabel = 'Biometric';

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricSettings() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final enrolled = await _localAuth.canCheckBiometrics;
      final types = (supported && enrolled)
          ? await _localAuth.getAvailableBiometrics()
          : const <BiometricType>[];
      final hasFace = types.contains(BiometricType.face);
      final hasFingerprint = types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.strong) ||
          types.contains(BiometricType.weak);
      final enabled = await SecureStorage().isBiometricEnabled();

      if (!mounted) return;
      setState(() {
        _biometricAvailable = hasFace || hasFingerprint;
        _biometricEnabled = enabled && _biometricAvailable;
        _biometricLabel = hasFace
            ? 'Face ID'
            : hasFingerprint
                ? 'Touch ID'
                : 'Biometric';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _biometricAvailable = false;
        _biometricEnabled = false;
        _biometricLabel = 'Biometric';
      });
    }
  }

  Future<void> _toggleBiometric(bool next) async {
    if (_biometricBusy) return;
    if (!_biometricAvailable && next) {
      showTopPopup(context, 'Biometric haijasanidiwa kwenye kifaa hiki.');
      return;
    }

    setState(() => _biometricBusy = true);
    try {
      if (next) {
        final supported = await _localAuth.isDeviceSupported();
        final enrolled = await _localAuth.canCheckBiometrics;
        final availableTypes = (supported && enrolled)
            ? await _localAuth.getAvailableBiometrics()
            : const <BiometricType>[];
        if (!supported || !enrolled || availableTypes.isEmpty) {
          if (mounted) {
            showTopPopup(
                context, 'Tafadhali sanidi Face ID/alama ya kidole kwanza.');
          }
          return;
        }

        final verified = await _localAuth.authenticate(
          localizedReason: 'Thibitisha utambulisho kuwasha $_biometricLabel',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
        if (!verified) {
          if (mounted) {
            showTopPopup(context, 'Uthibitishaji umeshindikana.');
          }
          return;
        }
      }

      await SecureStorage().setBiometricEnabled(next);
      if (next) {
        final token = await SecureStorage().getToken();
        if (token != null && token.isNotEmpty) {
          await SecureStorage().saveBiometricToken(token);
        }
      } else {
        await SecureStorage().clearBiometricToken();
      }

      if (!mounted) return;
      setState(() => _biometricEnabled = next);
      showTopPopup(
        context,
        next
            ? '$_biometricLabel imewashwa kwa akaunti hii.'
            : '$_biometricLabel imezimwa kwa akaunti hii.',
        isError: false,
      );
    } catch (_) {
      if (mounted) {
        showTopPopup(context, 'Imeshindikana kubadili biometric.');
      }
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final userName =
            auth.userFullName.isNotEmpty ? auth.userFullName : 'Mkufunzi';
        final userEmail =
            auth.userEmail.isNotEmpty ? auth.userEmail : 'Hakuna barua pepe';
        final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'M';
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return CustomScrollView(
          controller: _scroll,
          slivers: [
              SliverAppBar(
                expandedHeight: _expandedHeight,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: const Color(0xFF3D1800),
                title: AnimatedBuilder(
                  animation: _scroll,
                  builder: (context, _) {
                    final show = _scroll.hasClients &&
                        _scroll.offset > (_expandedHeight - kToolbarHeight);
                    return AnimatedOpacity(
                      opacity: show ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        'Akaunti ya Mkufunzi',
                        style: GoogleFonts.montserrat(
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
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Toka',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w700)),
                          content: Text('Una uhakika unataka kutoka?',
                              style: GoogleFonts.montserrat()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Hapana',
                                  style: GoogleFonts.montserrat(
                                      color: const Color(0xFF9E8070))),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.read<AuthProvider>().logout();
                                context.go('/login');
                              },
                              child: Text('Ndiyo, Toka',
                                  style: GoogleFonts.montserrat(
                                      color: const Color(0xFFB71C1C),
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF2A0F04),
                          Color(0xFF3D1800),
                          Color(0xFF7B3A10)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Akaunti',
                              style: GoogleFonts.montserrat(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Mipangilio ya Mkufunzi',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.60),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE87722).withValues(alpha: 0.08),
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
                                color: const Color(0xFFE87722), width: 2.5),
                          ),
                          child: ClipOval(
                            child: auth.userAvatar != null
                                ? CachedNetworkImage(
                                    imageUrl: auth.userAvatar!,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _avatarFallback(initial),
                                  )
                                : _avatarFallback(initial),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color ??
                                        const Color(0xFF1A0A00),
                                  )),
                              const SizedBox(height: 2),
                              Text(userEmail,
                                  style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: const Color(0xFF9E8070))),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFE87722).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFFE87722)
                                          .withValues(alpha: 0.4)),
                                ),
                                child: Text('Mkufunzi',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE87722),
                                    )),
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
                      _buildMenuGroup('Wasifu Wangu', [
                        _buildMenuItem(
                          Icons.edit_outlined,
                          const Color(0xFFE87722),
                          'Hariri Wasifu',
                          onTap: () => context.push('/profile/edit'),
                        ),
                        _buildMenuItem(
                          Icons.manage_accounts_outlined,
                          const Color(0xFF3D1800),
                          'Mipangilio ya Akaunti',
                          onTap: () => context.push('/profile'),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildMenuGroup('Kazi Yangu', [
                        _buildMenuItem(
                          Icons.dashboard_outlined,
                          const Color(0xFF3D1800),
                          'Dashibodi ya Mkufunzi',
                          onTap: () => context.push('/trainer/dashboard'),
                        ),
                        _buildMenuItem(
                          Icons.school_outlined,
                          const Color(0xFFE87722),
                          'Kozi Zangu',
                          onTap: () => context.push('/trainer/dashboard'),
                        ),
                        _buildMenuItem(
                          Icons.workspace_premium_outlined,
                          const Color(0xFF7B3A10),
                          'Vyeti vya Wanafunzi',
                          onTap: () => context.push('/trainer/dashboard'),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildMenuGroup('Fedha', [
                        _buildMenuItem(
                          Icons.account_balance_wallet_outlined,
                          const Color(0xFFE87722),
                          'Mkoba Wangu',
                          onTap: () => context.push('/wallet'),
                        ),
                        _buildMenuItem(
                          Icons.receipt_long_outlined,
                          const Color(0xFF6A1B9A),
                          'Historia ya Malipo',
                          onTap: () => context.push('/payment/history'),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildMenuGroup('Msaada', [
                        _buildMenuItem(
                          Icons.headset_mic_outlined,
                          const Color(0xFFE87722),
                          'Msaada na Maswali',
                          onTap: () => context.push('/support'),
                        ),
                        _buildMenuItem(
                          Icons.gavel_outlined,
                          const Color(0xFF3D1800),
                          'Masharti ya Matumizi',
                          onTap: () => context.push('/terms'),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildMenuGroup('Usalama', [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE87722).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _biometricLabel == 'Face ID'
                                  ? Icons.face_retouching_natural_rounded
                                  : Icons.fingerprint_rounded,
                              color: const Color(0xFFE87722),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            'Ingia kwa $_biometricLabel',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyLarge?.color ??
                                  const Color(0xFF1A0A00),
                            ),
                          ),
                          subtitle: Text(
                            _biometricAvailable
                                ? 'Washa au zima biometric kwa akaunti hii'
                                : 'Haipatikani kwenye kifaa hiki',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: const Color(0xFF9E8070),
                            ),
                          ),
                          trailing: Switch(
                            value: _biometricEnabled && _biometricAvailable,
                            onChanged: (_biometricAvailable && !_biometricBusy)
                                ? _toggleBiometric
                                : null,
                            activeColor: const Color(0xFFE87722),
                            activeTrackColor: const Color(0xFFE87722)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text('Toka',
                                    style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.w700)),
                                content: Text('Una uhakika unataka kutoka?',
                                    style: GoogleFonts.montserrat()),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Hapana',
                                        style: GoogleFonts.montserrat(
                                            color: const Color(0xFF9E8070))),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.read<AuthProvider>().logout();
                                      context.go('/login');
                                    },
                                    child: Text('Ndiyo, Toka',
                                        style: GoogleFonts.montserrat(
                                            color: const Color(0xFFB71C1C),
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.logout,
                              color: Color(0xFFB71C1C), size: 20),
                          label: Text('Toka',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB71C1C),
                              )),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFFFFEBEE), width: 1.5),
                            backgroundColor: const Color(0xFFFFEBEE),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _avatarFallback(String initial) {
    return Container(
      width: 88,
      height: 88,
      color: const Color(0xFFE87722),
      child: Center(
        child: Text(initial,
            style: GoogleFonts.montserrat(
                fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _buildMenuGroup(String title, List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                Text(title,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9E8070),
                      letterSpacing: 0.5,
                    )),
              ],
            ),
          ),
          ...items.asMap().entries.map((entry) => Column(
                children: [
                  if (entry.key > 0)
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : const Color(0xFFF0E4DA),
                      indent: 56,
                    ),
                  entry.value,
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    Color iconColor,
    String label, {
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
      title: Text(label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color ??
                const Color(0xFF1A0A00),
          )),
      trailing: const Icon(Icons.chevron_right,
          color: Color(0xFFE8D5C8), size: 18),
      onTap: onTap,
    );
  }
}
