import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<dynamic> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      final res = await ApiClient().dio.get('/api/v1/payments/checkout/');
      final data = res.data;
      final results = data is Map
          ? (data['results'] as List? ?? [])
          : (data as List? ?? []);
      if (!mounted) return;
      setState(() {
        _payments = results;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatPrice(dynamic price) {
    try {
      final formatter = NumberFormat('#,###', 'en_US');
      return 'TZS ${formatter.format(double.parse(price.toString()))}';
    } catch (_) {
      return 'TZS $price';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Historia ya Malipo',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: KarakanaWaveLoader(color: Color(0xFFE87722)),
                )
              : _payments.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: AppSpacing.sectionPadding,
                      itemCount: _payments.length,
                      itemBuilder: (_, i) {
                        final payment = _payments[i] as Map;
                        final isSuccessful = payment['is_successful'] == true;
                        final courseData = payment['course'];
                        final courseTitle = courseData is Map
                            ? courseData['title'] as String? ?? 'Kozi'
                            : 'Kozi';
                        final amount = payment['amount'];
                        final method = payment['method'] as String? ?? '';
                        final paidAt = payment['paid_at'] as String? ?? '';

                        String formattedDate = '';
                        try {
                          formattedDate = DateFormat('dd MMM yyyy')
                              .format(DateTime.parse(paidAt));
                        } catch (_) {
                          formattedDate = paidAt;
                        }

                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs),
                          padding: AppSpacing.cardPadding,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x08C4620A),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSuccessful
                                      ? (isDark
                                          ? const Color(0xFF2A1A0A)
                                          : const Color(0xFFF5E6D8))
                                      : const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(AppSpacing.sm + AppSpacing.xs),
                                ),
                                child: Icon(
                                  isSuccessful
                                      ? Icons.check_circle_outline
                                      : Icons.error_outline,
                                  color: isSuccessful
                                      ? const Color(0xFFE87722)
                                      : const Color(0xFFB71C1C),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      courseTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: const Color(0xFF3D1800),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm - AppSpacing.xs / 2,
                                            vertical: AppSpacing.xs / 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF2A1A0A)
                                                : const Color(0xFFF5E6D8),
                                            borderRadius:
                                                BorderRadius.circular(AppSpacing.sm - AppSpacing.xs / 2),
                                          ),
                                          child: Text(
                                            method.toUpperCase(),
                                            style: AppTextStyles.labelSmall.copyWith(
                                              color: const Color(0xFFE87722),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          formattedDate,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: const Color(0xFF9E8070),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatPrice(amount),
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: const Color(0xFFE87722),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs - 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSuccessful
                                          ? (isDark
                                              ? const Color(0xFF2A1A0A)
                                              : const Color(0xFFF5E6D8))
                                          : const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(AppSpacing.sm + AppSpacing.xs / 2),
                                    ),
                                    child: Text(
                                      isSuccessful ? 'Imefaulu' : 'Imeshindwa',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: isSuccessful
                                            ? const Color(0xFFE87722)
                                            : const Color(0xFFB71C1C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    )),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Color(0xFFE87722),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Hakuna Historia ya Malipo',
            style: AppTextStyles.h3.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color ??
                  const Color(0xFF1A0A00),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE87722),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              'Tafuta Kozi',
              style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
