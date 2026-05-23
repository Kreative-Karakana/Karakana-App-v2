import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/secure_storage.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/common/top_popup.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final ScrollController _scrollController = ScrollController();
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _biometricBusy = false;
  String _biometricLabel = 'Biometric';
  bool _showPinnedTopBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadBiometricSettings();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final shouldShow = _scrollController.offset > 8;
    if (shouldShow != _showPinnedTopBar && mounted) {
      setState(() => _showPinnedTopBar = shouldShow);
    }
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
          if (mounted) showTopPopup(context, 'Tafadhali sanidi Face ID/alama ya kidole kwenye kifaa kwanza.');
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
          if (mounted) showTopPopup(context, 'Uthibitishaji umeshindikana. Biometric haijawashwa.');
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
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      String msg;
      if (code.contains('notenrolled') ||
          code.contains('passcodenotenrolled') ||
          code.contains('not_available')) {
        msg = 'Hakuna Face ID/alama ya kidole iliyosajiliwa kwenye kifaa.';
      } else if (code.contains('lockedout') || code.contains('permanentlylockedout')) {
        msg = 'Biometric imefungwa kwa muda. Tumia nywila ya kifaa kisha ujaribu tena.';
      } else if (code.contains('no_biometric_hardware') || code.contains('notavailable')) {
        msg = 'Kifaa hiki hakina uwezo wa biometric.';
      } else {
        msg = 'Biometric haijapatikana kwa sasa kwenye kifaa hiki.';
      }
      if (mounted) {
        showTopPopup(context, msg);
      }
    } catch (_) {
      if (mounted) {
        showTopPopup(context, 'Imeshindikana kubadili mipangilio ya biometric.');
      }
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  Future<void> _deleteAccount(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Futa Akaunti',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Je, una uhakika unataka kufuta akaunti yako? Hatua hii haiwezi kutenduliwa na data yako yote itafutwa kabisa.',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hapana',
              style: GoogleFonts.montserrat(color: const Color(0xFF9E8070)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Ndio, Futa',
              style: GoogleFonts.montserrat(
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

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Tutakukosa! 💙',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Akaunti yako imefutwa. Asante kwa muda wako pamoja nasi — karibu tena wakati wowote!',
            style: GoogleFonts.montserrat(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Kwa heri',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

      if (!context.mounted) return;
      await auth.logout();
      context.go('/login');
    } catch (_) {
      if (!context.mounted) return;
      showTopPopup(context, 'Imeshindikana kufuta akaunti. Jaribu tena.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final userName = auth.userFullName.isNotEmpty ? auth.userFullName : 'Mtumiaji wa Karakana';
        final userEmail = auth.userEmail.isNotEmpty ? auth.userEmail : 'Hakuna barua pepe';
        final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'K';

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              if (_showPinnedTopBar)
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                  title: Text(
                    'Akaunti',
                    style: GoogleFonts.montserrat(
                      fontSize: AppTextStyles.h3.fontSize,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color ??
                          const Color(0xFF1A0A00),
                    ),
                  ),
                  systemOverlayStyle: const SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.dark,
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout, color: Color(0xFF1A0A00)),
                      onPressed: () {
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
                                  style: GoogleFonts.montserrat(color: const Color(0xFF9E8070)),
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
                      },
                    ),
                  ],
                ),
              SliverToBoxAdapter(
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: const SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.light,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2A0F04), Color(0xFF3D1800), Color(0xFF7B3A10)],
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
                              AppSpacing.lg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Akaunti',
                                  style: GoogleFonts.montserrat(
                                    fontSize:
                                        (AppTextStyles.displayLarge.fontSize ??
                                                32) -
                                            1,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Wasifu na Mipangilio Yako',
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
              // Profile card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg - AppSpacing.xs, AppSpacing.md, AppSpacing.lg - AppSpacing.xs, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md + 2,
                        horizontal: AppSpacing.lg - AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFECE7E2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x0A000000),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
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
                                style: GoogleFonts.montserrat(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1A0A00),
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
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + AppSpacing.xs / 2, vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE87722).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.cardLg),
                                  border: Border.all(
                                    color: const Color(0xFFE87722).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  auth.isTrainer ? 'Mkufunzi' : 'Mwanafunzi',
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
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg - AppSpacing.xs, AppSpacing.md, AppSpacing.lg - AppSpacing.xs, 0),
                  child: Column(
                    children: [
                      _buildMenuGroup(
                        'Kujifunza Kwangu',
                        [
                          _buildMenuItem(
                            Icons.school_outlined,
                            const Color(0xFFE87722),
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
                      const SizedBox(height: AppSpacing.md),
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
                            Icons.payment_outlined,
                            const Color(0xFFE87722),
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
                      const SizedBox(height: AppSpacing.md),
                      _buildMenuGroup(
                        'Msaada',
                        [
                          _buildMenuItem(
                            Icons.headset_mic_outlined,
                            const Color(0xFFE87722),
                            'Msaada',
                            onTap: () => context.push('/support'),
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
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          return _buildMenuGroup(
                            'Mipangilio',
                            [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE87722).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    themeProvider.isDark
                                        ? Icons.dark_mode
                                        : Icons.light_mode,
                                    color: const Color(0xFFE87722),
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  themeProvider.isDark
                                      ? 'Hali ya Giza'
                                      : 'Hali ya Mwanga',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1A0A00),
                                  ),
                                ),
                                trailing: Switch(
                                  value: themeProvider.isDark,
                                  onChanged: (_) => themeProvider.toggleTheme(),
                                  activeColor: const Color(0xFFE87722),
                                  activeTrackColor: const Color(0xFFE87722)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
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
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (auth.isTrainer) ...[
                        _buildMenuGroup(
                          'Mkufunzi',
                          [
                            _buildMenuItem(
                              Icons.dashboard_outlined,
                              const Color(0xFF3D1800),
                              'Dashibodi ya Mkufunzi',
                              onTap: () => context.push('/trainer/dashboard'),
                            ),
                            _buildMenuItem(
                              Icons.add_box_outlined,
                              const Color(0xFFE87722),
                              'Unda Kozi Mpya',
                              onTap: () => context.push('/trainer/course-builder'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ] else ...[
                        GestureDetector(
                          onTap: () => context.push('/trainer/apply'),
                          child: Container(
                            padding: AppSpacing.cardPadding,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A0A00), Color(0xFF3D1800), Color(0xFF7B3A10)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.modal),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3D1800).withValues(alpha: 0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppRadius.card),
                                  ),
                                  child: const Icon(Icons.school, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kuwa Mkufunzi',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Fundisha na upate kipato',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          color: Colors.white.withValues(alpha: 0.82),
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
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text('Toka', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                                    content: Text('Una uhakika unataka kutoka?', style: GoogleFonts.montserrat()),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Hapana', style: GoogleFonts.montserrat(color: const Color(0xFF9E8070))),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          context.read<AuthProvider>().logout();
                                          context.go('/login');
                                        },
                                        child: Text('Ndiyo, Toka', style: GoogleFonts.montserrat(color: const Color(0xFFB71C1C), fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.logout, color: Color(0xFF1A0A00), size: 18),
                              label: Text('Toka', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A0A00))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE8D5C8), width: 1.5),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md - AppSpacing.xs / 2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _deleteAccount(context, auth),
                              icon: const Icon(Icons.delete_forever_outlined, color: Colors.white, size: 18),
                              label: Text('Futa Akaunti', style: GoogleFonts.montserrat(fontSize: AppTextStyles.bodyMedium.fontSize, fontWeight: FontWeight.w600, color: Colors.white)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFB71C1C), width: 1.5),
                                backgroundColor: const Color(0xFFB71C1C),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md - AppSpacing.xs / 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.lg),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + AppSpacing.xs, vertical: AppSpacing.sm - 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + AppSpacing.xs / 2, vertical: AppSpacing.sm + 1),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
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
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm + AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
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
                        color: isDark ? Colors.white10 : const Color(0xFFF0E4DA),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
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
          color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1A0A00),
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
    );
  }
}




