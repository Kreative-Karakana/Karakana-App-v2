import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/secure_storage.dart';
import '../../../widgets/common/top_popup.dart';
import '../../auth/providers/auth_provider.dart';

class TrainerAccountScreen extends StatefulWidget {
  final void Function(int tabIndex)? onTabSwitch;
  final bool embeddedInDashboard;
  const TrainerAccountScreen({
    super.key,
    this.onTabSwitch,
    this.embeddedInDashboard = false,
  });

  @override
  State<TrainerAccountScreen> createState() => _TrainerAccountScreenState();
}

class _TrainerAccountScreenState extends State<TrainerAccountScreen> {
  static const double _accountHeaderHeight = 136;
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

  Future<String?> _currentAccountId() async {
    final auth = context.read<AuthProvider>();
    return auth.userId?.toString() ?? await SecureStorage().getUserId();
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
      final accountId = await _currentAccountId();
      final enabled = accountId == null
          ? false
          : await SecureStorage().isBiometricEnabledForAccount(accountId);

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

      final accountId = await _currentAccountId();
      if (accountId == null || accountId.isEmpty) {
        if (mounted) {
          showTopPopup(context, 'Akaunti haijatambuliwa. Ingia tena kwanza.');
        }
        return;
      }

      await SecureStorage().setBiometricEnabledForAccount(accountId, next);
      if (next) {
        final token = await SecureStorage().getToken();
        if (token != null && token.isNotEmpty) {
          await SecureStorage().saveBiometricTokenForAccount(accountId, token);
          await SecureStorage().setActiveBiometricAccountId(accountId);
        }
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
          // When embedded in the dashboard's NestedScrollView the inner
          // scroll view must use the PrimaryScrollController that
          // NestedScrollView injects — otherwise the SliverAppBar never
          // receives scroll notifications and the hero won't collapse.
          controller: widget.embeddedInDashboard ? null : _scroll,
          slivers: [
            if (!widget.embeddedInDashboard) _buildStandaloneHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg - AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.lg - AppSpacing.xs,
                  0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md + 2,
                    horizontal: AppSpacing.lg - AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFECE7E2),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE87722),
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
                                  width: 64,
                                  height: 64,
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
                            Text(
                              userName,
                              style: GoogleFonts.montserrat(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    const Color(0xFF1A0A00),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs / 2),
                            Text(
                              userEmail,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: const Color(0xFF9E8070),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm + AppSpacing.xs / 2,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE87722)
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.cardLg),
                                border: Border.all(
                                  color: const Color(0xFFE87722)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'Mkufunzi',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE87722),
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg - AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.lg - AppSpacing.xs,
                  0,
                ),
                child: Column(
                  children: [
                    _buildMenuGroup(
                      'Akaunti',
                      [
                        _buildMenuItem(
                          Icons.person_outlined,
                          const Color(0xFF3D1800),
                          'Hariri Wasifu',
                          onTap: () => context.push('/profile/edit'),
                        ),
                        _buildMenuItem(
                          Icons.account_balance_wallet_outlined,
                          const Color(0xFF6A1B9A),
                          'Mkoba Wangu',
                          onTap: () => context.push('/wallet'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildMenuGroup(
                      'Kazi ya Mkufunzi',
                      [
                        _buildMenuItem(
                          Icons.dashboard_outlined,
                          const Color(0xFF3D1800),
                          'Dashibodi ya Mkufunzi',
                          subtitle: 'Muhtasari wa mapato, kozi na wanafunzi',
                          onTap: () => widget.onTabSwitch?.call(0),
                        ),
                        _buildMenuItem(
                          Icons.school_outlined,
                          const Color(0xFFE87722),
                          'Kozi Zangu',
                          onTap: () => widget.onTabSwitch?.call(1),
                        ),
                        _buildMenuItem(
                          Icons.workspace_premium_outlined,
                          const Color(0xFF7B3A10),
                          'Vyeti vya Wanafunzi',
                          onTap: () => widget.onTabSwitch?.call(3),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildMenuGroup(
                      'Msaada',
                      [
                        _buildMenuItem(
                          Icons.headset_mic_outlined,
                          const Color(0xFFE87722),
                          'Msaada',
                          onTap: () => context.push('/support', extra: {
                            'userEmail': auth.userEmail,
                            'userName': auth.userFullName,
                            'isTrainer': true,
                          }),
                        ),
                        _buildMenuItem(
                          Icons.notifications_outlined,
                          const Color(0xFFE87722),
                          'Arifa',
                          onTap: () => context.push('/notifications'),
                        ),
                        _buildMenuItem(
                          Icons.gavel_outlined,
                          const Color(0xFF3D1800),
                          'Masharti na Vigezo',
                          onTap: () => context.push('/terms'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildMenuGroup(
                      'Mipangilio',
                      [
                        _buildMenuItem(
                          Icons.lock_reset_rounded,
                          const Color(0xFF3D1800),
                          'Badilisha Nywila',
                          subtitle: 'Weka nywila mpya ya akaunti yako',
                          onTap: () => context.push('/profile/change-password'),
                        ),
                        _buildSettingTile(
                          icon: _biometricLabel == 'Face ID'
                              ? Icons.face_retouching_natural_rounded
                              : Icons.fingerprint_rounded,
                          title: 'Ingia kwa $_biometricLabel',
                          subtitle: _biometricAvailable
                              ? 'Washa au zima biometric kwa akaunti hii'
                              : 'Haipatikani kwenye kifaa hiki',
                          trailing: Switch(
                            value: _biometricEnabled && _biometricAvailable,
                            onChanged: (_biometricAvailable && !_biometricBusy)
                                ? _toggleBiometric
                                : null,
                            activeThumbColor: const Color(0xFFE87722),
                            activeTrackColor:
                                const Color(0xFFE87722).withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
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
                                color: Color(0xFF1A0A00), size: 18),
                            label: Text('Toka',
                                style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A0A00))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFFE8D5C8), width: 1.5),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  title: Text('Futa Akaunti?',
                                      style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1A0A00))),
                                  content: Text(
                                    'Akaunti yako itafutwa kabisa na data yote itapotea. Hii haiwezi kurejeshwa.',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        color: const Color(0xFF7B3A10),
                                        height: 1.5),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Hapana',
                                          style: GoogleFonts.montserrat(
                                              color: const Color(0xFF9E8070))),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        try {
                                          await context
                                              .read<AuthProvider>()
                                              .deleteAccount();
                                          if (context.mounted) {
                                            context.go('/login');
                                          }
                                        } catch (_) {
                                          if (context.mounted) {
                                            showTopPopup(context,
                                                'Imeshindikana kufuta akaunti. Jaribu tena.');
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFB71C1C),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      child: Text('Ndiyo, Futa',
                                          style: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_forever_outlined,
                                color: Colors.white, size: 18),
                            label: Text('Futa Akaunti',
                                style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFFB71C1C), width: 1.5),
                              backgroundColor: const Color(0xFFB71C1C),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 24),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStandaloneHeader() {
    return SliverAppBar(
      expandedHeight: _accountHeaderHeight,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF3D1800),
      elevation: 0,
      titleSpacing: AppSpacing.lg - AppSpacing.xs,
      title: _CollapsedHeaderChrome(
        scrollController: _scroll,
        threshold: _accountHeaderHeight - kToolbarHeight - 28,
        child: Text(
          'Akaunti',
          style: GoogleFonts.montserrat(
            fontSize: AppTextStyles.h3.fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      actions: [
        _CollapsedHeaderChrome(
          scrollController: _scroll,
          threshold: _accountHeaderHeight - kToolbarHeight - 28,
          child: _buildLogoutAction(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2A0F04),
                  Color(0xFF3D1800),
                  Color(0xFF7B3A10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: -40,
                  right: -30,
                  child: Container(
                    width: 180,
                    height: 180,
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
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg - AppSpacing.xs,
                      AppSpacing.md - AppSpacing.xs / 2,
                      AppSpacing.lg - AppSpacing.xs,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Akaunti',
                          style: GoogleFonts.montserrat(
                            fontSize:
                                (AppTextStyles.displayLarge.fontSize ?? 32) - 1,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Wasifu na Mipangilio ya Mkufunzi',
                          style: GoogleFonts.montserrat(
                            fontSize: AppTextStyles.bodyMedium.fontSize,
                            color: Colors.white.withValues(alpha: 0.65),
                            height: 1.35,
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
    );
  }

  Widget _avatarFallback(String initial) {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFE87722),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGroup(String title, List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFECE7E2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm + AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9E8070),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          ...items.asMap().entries.map(
                (entry) => Column(
                  children: [
                    if (entry.key > 0)
                      Divider(
                        height: 1,
                        color:
                            isDark ? Colors.white10 : const Color(0xFFF0E4DA),
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 2,
        ),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        title: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color ??
                const Color(0xFF1A0A00),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.montserrat(
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
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 2,
        ),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE87722).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFE87722),
            size: 17,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color ??
                const Color(0xFF1A0A00),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF9E8070),
                ),
              )
            : null,
        trailing: trailing,
      ),
    );
  }

  Widget _buildLogoutAction() {
    return IconButton(
      icon: const Icon(Icons.logout, color: Colors.white),
      onPressed: _showLogoutDialog,
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Toka',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Una uhakika unataka kutoka?',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hapana',
              style: GoogleFonts.montserrat(
                color: const Color(0xFF9E8070),
              ),
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
              style: GoogleFonts.montserrat(
                color: const Color(0xFFB71C1C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsedHeaderChrome extends StatelessWidget {
  final ScrollController scrollController;
  final double threshold;
  final Widget child;

  const _CollapsedHeaderChrome({
    required this.scrollController,
    required this.threshold,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final isVisible =
            scrollController.hasClients && scrollController.offset > threshold;
        return IgnorePointer(
          ignoring: !isVisible,
          child: AnimatedOpacity(
            opacity: isVisible ? 1 : 0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: child,
          ),
        );
      },
    );
  }
}
