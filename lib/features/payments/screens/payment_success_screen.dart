import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5E6D8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFFE87722),
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.paymentSuccessTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h1.copyWith(
                          color: const Color(0xFF3D1800),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                      Text(
                        l10n.paymentSuccessSubtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h4.copyWith(
                          color: const Color(0xFF9E8070),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        width: double.infinity,
                        padding: AppSpacing.sectionPadding,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E6D8),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: const Color(0xFFE8D5C8)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.paymentSuccessStatusLabel,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: const Color(0xFF9E8070),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal:
                                        AppSpacing.sm + AppSpacing.xs / 2,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE87722),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.sm + AppSpacing.xs / 2),
                                  ),
                                  child: Text(
                                    l10n.paymentSuccessStatusValue,
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                                height: AppSpacing.sm + AppSpacing.xs),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.paymentSuccessDateLabel,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: const Color(0xFF9E8070),
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy')
                                      .format(DateTime.now()),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3D1800),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    l10n.paymentSuccessStartLearning,
                    style:
                        AppTextStyles.buttonLarge.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE87722),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  onPressed: () => context.go('/home'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  l10n.paymentSuccessBackHome,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF9E8070),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}
