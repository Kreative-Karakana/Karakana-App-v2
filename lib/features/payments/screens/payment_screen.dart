import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/top_popup.dart';
import '../utils/payment_status.dart';

class PaymentScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;
  final double coursePrice;
  final String? courseThumbnail;

  const PaymentScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.coursePrice,
    this.courseThumbnail,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedProvider;
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'en_US');
    return 'TZS ${formatter.format(price)}';
  }

  String _normalizePhone(String raw) {
    final phone = raw.trim().replaceAll(' ', '').replaceAll('-', '');
    if (phone.startsWith('255')) return phone;
    if (phone.startsWith('0')) return '255${phone.substring(1)}';
    return '255$phone';
  }

  void _showError(String message) {
    if (!mounted) return;
    showTopPopup(context, message);
  }

  Future<void> _processPayment() async {
    final phone = _normalizePhone(_phoneController.text);
    if (phone.length < 12) {
      _showError('Weka nambari sahihi ya simu (mfano: 0712345678)');
      return;
    }

    setState(() => _isProcessing = true);

    // Show "waiting for confirmation" dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.cardLg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KarakanaWaveLoader(size: 30),
            const SizedBox(height: AppSpacing.md + AppSpacing.xs / 2),
            Text(
              'Inashughulikia Malipo...',
              style: AppTextStyles.h3.copyWith(color: const Color(0xFF3D1800)),
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs / 2),
            Text(
              'Thibitisha malipo kwenye simu yako.\nUsifunge programu hii.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: const Color(0xFF5C3D2E), height: 1.5),
            ),
          ],
        ),
      ),
    );

    try {
      // 1. Initiate checkout
      final checkoutRes = await ApiClient().dio.post(
        '/api/v1/payments/checkout/',
        data: {
          'accountNumber': phone,
          'provider': _selectedProvider,
          'course_id': widget.courseId
        },
      );
      debugPrint('[PAYMENT] checkout response: ${checkoutRes.data}');

      final externalId = checkoutRes.data['external_id'] as String?;
      final checkoutUrl = checkoutRes.data['checkout_url'] as String?;
      final initiationSuccess = checkoutRes.data['success'] == true;
      final responseDesc = checkoutRes.data['response_desc']?.toString();
      final awaitsUssd = PaymentStatusContract.awaitsUssd(checkoutRes.data);
      if (externalId == null || externalId.isEmpty) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        _showError('Hitilafu ya kuanzisha malipo. Jaribu tena.');
        return;
      }

      // EVMAK MNO flow may not return a checkout URL. In that case we proceed
      // directly to status polling after successful initiation.
      if (awaitsUssd && initiationSuccess) {
        // Keep dialog open and continue to polling loop below.
      } else if (awaitsUssd && !initiationSuccess) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        _showError(
          responseDesc?.isNotEmpty == true
              ? ApiClient().localizeErrorMessage(responseDesc!)
              : 'Malipo hayakuanzishwa. Jaribu tena.',
        );
        return;
      } else if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        final uri = Uri.tryParse(checkoutUrl);
        if (uri != null) {
          var opened =
              await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!opened) {
            opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
          }
          if (!opened) {
            opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
          if (!opened) {
            if (mounted) Navigator.of(context, rootNavigator: true).pop();
            _showError(
                'Imeshindikana kufungua ukurasa wa malipo. Jaribu tena.');
            return;
          }
        }
      } else {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        _showError('Kiungo cha malipo hakikupatikana. Jaribu tena.');
        return;
      }

      // 2. Poll for payment status.
      // EVMAK MNO can take longer before callback confirmation.
      final maxPollAttempts = awaitsUssd ? 20 : 10;
      bool success = false;
      for (int i = 0; i < maxPollAttempts; i++) {
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;

        try {
          final statusRes =
              await ApiClient().dio.get('/api/v1/payments/$externalId/');
          debugPrint(
            '[PAYMENT] poll $i/$maxPollAttempts external_id=$externalId status=${statusRes.data}',
          );
          if (PaymentStatusContract.isSettled(statusRes.data)) {
            success = true;
            break;
          }
          // If explicitly failed (not just pending), stop early
          final failed = PaymentStatusContract.isFailed(statusRes.data);
          if (failed) break;
        } catch (_) {
          // Network hiccup during polling — keep trying
        }
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close dialog

      if (success) {
        context.go('/payment/success');
      } else {
        _showError(
            'Malipo hayakukamilika. Thibitisha kwenye simu yako na ujaribu tena.');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showError(ApiClient().parseError(e));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const providers = [
      {
        'id': 'Mpesa',
        'name': 'Vodacom',
        'color': Color(0xFFE87722),
        'logo': 'mno_logos/mpesa.png'
      },
      {
        'id': 'Tigo',
        'name': 'Mix by Yas',
        'color': Color(0xFF3D1800),
        'logo': 'mno_logos/mix_by_yas.png',
      },
      {
        'id': 'Airtel',
        'name': 'Airtel',
        'color': Color(0xFF3D1800),
        'logo': 'mno_logos/airtel.png',
      },
      {
        'id': 'Halopesa',
        'name': 'HaloPesa',
        'color': Color(0xFF3D1800),
        'logo': 'mno_logos/halopesa.png',
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text('Lipia Kozi',
            style: AppTextStyles.h3.copyWith(color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.sectionPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x14C4620A),
                        blurRadius: 10,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    if (widget.courseThumbnail != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                            AppSpacing.sm + AppSpacing.xs / 2),
                        child: CachedNetworkImage(
                          imageUrl: widget.courseThumbnail!,
                          width: 72,
                          height: 64,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _thumbFallback(),
                        ),
                      )
                    else
                      _thumbFallback(),
                    const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.courseTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: const Color(0xFF3D1800),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _formatPrice(widget.coursePrice),
                            style: AppTextStyles.price.copyWith(
                              fontSize: 18,
                              color: const Color(0xFFE87722),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Chagua Njia ya Malipo',
                style:
                    AppTextStyles.h4.copyWith(color: const Color(0xFF3D1800)),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tumia nambari yako ya simu kulipa',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: const Color(0xFF9E8070)),
              ),
              const SizedBox(height: AppSpacing.md),
              ...providers.map((provider) {
                final isSelected = _selectedProvider == provider['id'];
                final color = provider['color']! as Color;
                return GestureDetector(
                  onTap: () => setState(
                      () => _selectedProvider = provider['id']! as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(
                        bottom: AppSpacing.sm + AppSpacing.xs / 2),
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      border: Border.all(
                        color: isSelected ? color : const Color(0xFFE8D5C8),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? color.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: isSelected ? 12 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.sm + AppSpacing.xs / 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              provider['logo']! as String,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                  Icons.phone_android,
                                  color: color,
                                  size: 22),
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: AppSpacing.md - AppSpacing.xs / 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider['name']! as String,
                                style: AppTextStyles.h4
                                    .copyWith(color: const Color(0xFF3D1800)),
                              ),
                              Text(
                                'Lipa kwa ${provider['name']}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF9E8070),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isSelected ? color : const Color(0xFFE8D5C8),
                              width: 2,
                            ),
                            color: isSelected
                                ? color.withValues(alpha: 0.12)
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? Icon(Icons.check, color: color, size: 14)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF003087), Color(0xFF009FE3)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.account_balance_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lipa kwa Urahisi Zaidi!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Tumia akaunti yako ya benki au MNO yoyote Tanzania.',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                    ),
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm + AppSpacing.xs / 2,
                                vertical: AppSpacing.sm - AppSpacing.xs / 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Jua Zaidi',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF003087),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.xs,
                        right: AppSpacing.xs,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Ad',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Nambari ya Simu',
                style:
                    AppTextStyles.h4.copyWith(color: const Color(0xFF3D1800)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E6D8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8D5C8)),
                    ),
                    child: Center(
                      child: Text(
                        '+255',
                        style: AppTextStyles.h4
                            .copyWith(color: const Color(0xFF3D1800)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.h4
                          .copyWith(color: const Color(0xFF3D1800)),
                      decoration: InputDecoration(
                        hintText: '7XX XXX XXX',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFFBDA99C),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFFF8F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          borderSide:
                              const BorderSide(color: Color(0xFFE8D5C8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          borderSide: const BorderSide(
                              color: Color(0xFFE87722), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md + AppSpacing.xs / 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Mfano: 0712345678 au 712345678',
                style: AppTextStyles.caption
                    .copyWith(color: const Color(0xFFBDA99C)),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: AppSpacing.sectionPadding,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: const Color(0xFFE8D5C8)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jumla',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: const Color(0xFF9E8070)),
                        ),
                        Text(
                          _formatPrice(widget.coursePrice),
                          style: AppTextStyles.buttonLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D1800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ada ya Malipo',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: const Color(0xFF9E8070)),
                        ),
                        Text(
                          'Bure',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: const Color(0xFFE87722)),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFF0E4DA), height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jumla ya Kulipa',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: const Color(0xFF3D1800)),
                        ),
                        Text(
                          _formatPrice(widget.coursePrice),
                          style: AppTextStyles.price.copyWith(
                            fontSize: 18,
                            color: const Color(0xFFE87722),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE87722),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    elevation: 0,
                  ),
                  onPressed: (_selectedProvider != null &&
                          _phoneController.text.isNotEmpty &&
                          !_isProcessing)
                      ? _processPayment
                      : null,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: KarakanaWaveLoader(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Lipa ${_formatPrice(widget.coursePrice)}',
                          style: AppTextStyles.buttonLarge
                              .copyWith(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 14, color: Color(0xFF9E8070)),
                  const SizedBox(width: 6),
                  Text(
                    'Malipo Salama na Karakana',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: const Color(0xFF9E8070)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbFallback() {
    return Container(
      width: 72,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.school_outlined, color: Color(0xFFE87722)),
    );
  }
}
