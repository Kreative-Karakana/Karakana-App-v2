import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/top_popup.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _wallet;
  List<dynamic> _checkouts = [];
  bool _isLoading = true;
  bool _balanceVisible = false;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    try {
      final walletRes = await ApiClient().dio.get('/api/v1/wallet/me/');
      final checkoutRes =
          await ApiClient().dio.get('/api/v1/wallet/checkouts/');
      final checkoutData = checkoutRes.data;
      if (!mounted) return;
      setState(() {
        _wallet = Map<String, dynamic>.from(walletRes.data as Map);
        _checkouts = checkoutData is Map
            ? (checkoutData['results'] as List? ?? [])
            : (checkoutData as List? ?? []);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatPrice(dynamic price) {
    try {
      return NumberFormat('#,###').format(double.parse(price.toString()));
    } catch (_) {
      return '$price';
    }
  }

  void _showWithdrawSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.modal)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5C8),
                borderRadius: BorderRadius.circular(AppSpacing.xs / 2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Omba Malipo',
              style: AppTextStyles.h3.copyWith(color: const Color(0xFF3D1800)),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kiasi cha Kutoa',
                prefixIcon: const Icon(
                  Icons.payments_outlined,
                  color: Color(0xFFE87722),
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(
                    color: Color(0xFFE87722),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            TextField(
              controller: _remarkController,
              decoration: InputDecoration(
                labelText: 'Maelezo (hiari)',
                prefixIcon: const Icon(
                  Icons.notes_outlined,
                  color: Color(0xFFE87722),
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(
                    color: Color(0xFFE87722),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE87722),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                onPressed: () async {
                  final amount =
                      double.tryParse(_amountController.text.trim()) ?? 0;
                  if (amount < 500) {
                    showTopPopup(context, 'Kiasi cha chini ni TZS 500.');
                    return;
                  }
                  try {
                    await ApiClient().dio.post(
                      '/api/v1/wallet/checkouts/',
                      data: {
                        'amount': _amountController.text.trim(),
                        'remark': _remarkController.text,
                      },
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    _amountController.clear();
                    _remarkController.clear();
                    showTopPopup(context, 'Ombi limetumwa kikamilifu!',
                        isError: false);
                    _loadWallet();
                  } catch (_) {
                    if (!mounted) return;
                    showTopPopup(context, 'Hitilafu. Jaribu tena.');
                  }
                },
                child: Text(
                  'Tuma Ombi',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReceipt(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildCheckoutItem(Map checkout) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSuccessful = checkout['is_successful'] == true;
    final remark = checkout['remark'] as String? ?? '';
    final amount = checkout['amount'];
    final date = checkout['initiated_at'] as String? ?? '';
    final receiptUrl = checkout['receipt_image'] as String?;
    String formattedDate = '';
    try {
      formattedDate = DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {
      formattedDate = date;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs / 2),
      padding: const EdgeInsets.all(AppSpacing.md - AppSpacing.xs / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.sm + AppSpacing.xs),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 1))
        ],
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSuccessful
                ? (isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8))
                : const Color(0xFFFFA726).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.sm + AppSpacing.xs / 2),
          ),
          child: Icon(
            isSuccessful ? Icons.check_circle_outline : Icons.pending_outlined,
            color: isSuccessful
                ? const Color(0xFFE87722)
                : const Color(0xFFFFA726),
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(remark.isEmpty ? 'Ombi la Malipo' : remark,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600, color: const Color(0xFF3D1800))),
          Row(children: [
            Text(formattedDate,
                style: AppTextStyles.caption.copyWith(color: const Color(0xFF9E8070))),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm - AppSpacing.xs / 2,
                vertical: AppSpacing.xs / 2,
              ),
              decoration: BoxDecoration(
                color: isSuccessful
                    ? const Color(0xFFE87722).withValues(alpha: 0.1)
                    : const Color(0xFFFFA726).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.sm - AppSpacing.xs / 2),
              ),
              child: Text(isSuccessful ? 'Imekamilika' : 'Inasubiri',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: isSuccessful
                          ? const Color(0xFFE87722)
                          : const Color(0xFFFFA726))),
            ),
          ]),
        ])),
        const SizedBox(width: AppSpacing.sm),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('TZS ${_formatPrice(amount)}',
              style: AppTextStyles.labelLarge.copyWith(
                  color: isSuccessful
                      ? const Color(0xFFE87722)
                      : const Color(0xFFFFA726))),
          if (isSuccessful && receiptUrl != null && receiptUrl.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: () => _openReceipt(receiptUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs - 1,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A1A0A)
                      : const Color(0xFFF5E6D8),
                  borderRadius: BorderRadius.circular(AppSpacing.sm - AppSpacing.xs / 2),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.receipt_outlined,
                      size: 11, color: Color(0xFF7B3A10)),
                  const SizedBox(width: AppSpacing.xs - 1),
                  Text('Risiti',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFF7B3A10))),
                ]),
              ),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _buildCheckoutList(List<dynamic> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(emptyMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF9E8070)),
              textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg - AppSpacing.xs,
        AppSpacing.sm + AppSpacing.xs,
        AppSpacing.lg - AppSpacing.xs,
        AppSpacing.lg,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildCheckoutItem(items[i] as Map),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successful =
        _checkouts.where((c) => (c as Map)['is_successful'] == true).toList();
    final pending =
        _checkouts.where((c) => (c as Map)['is_successful'] != true).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF3D1800),
                  Color(0xFF7B3A10),
                  Color(0xFFE87722)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs / 2),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.sm + AppSpacing.xs / 2),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Mkoba Wangu',
                style: AppTextStyles.h3.copyWith(color: Colors.white)),
          ]),
          centerTitle: true,
        ),
        body: SafeArea(
            child: _isLoading
                ? const Center(
                    child: KarakanaWaveLoader(color: Color(0xFFE87722)))
                : Column(children: [
                    // ── BALANCE CARD ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg - AppSpacing.xs,
                        AppSpacing.md,
                        AppSpacing.lg - AppSpacing.xs,
                        AppSpacing.lg,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3D1800),
                              Color(0xFF7B3A10),
                              Color(0xFFE87722)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.modal),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFFE87722)
                                    .withValues(alpha: 0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 8))
                          ],
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Salio Linalopatikana',
                                              style: AppTextStyles.bodySmall.copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.7))),
                                          const SizedBox(height: AppSpacing.sm - AppSpacing.xs / 2),
                                          Text(
                                            _balanceVisible
                                                ? 'TZS ${_formatPrice(_wallet?['balance'] ?? 0)}'
                                                : 'TZS ••••••',
                                            style: AppTextStyles.displayMedium.copyWith(
                                                color: Colors.white),
                                          ),
                                        ]),
                                    GestureDetector(
                                      onTap: () => setState(() =>
                                          _balanceVisible = !_balanceVisible),
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.12),
                                            shape: BoxShape.circle),
                                        child: Icon(
                                          _balanceVisible
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ]),
                              const SizedBox(height: AppSpacing.lg),
                              Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text('Mapato Yote',
                                          style: AppTextStyles.caption.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.6))),
                                      const SizedBox(height: 4),
                                      Text(
                                        _balanceVisible
                                            ? 'TZS ${_formatPrice(_wallet?['total_income'] ?? 0)}'
                                            : 'TZS ••••',
                                        style: AppTextStyles.buttonLarge.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white),
                                      ),
                                    ])),
                                Container(
                                    width: 1,
                                    height: 32,
                                    color: Colors.white.withValues(alpha: 0.2)),
                                Expanded(
                                    child: Padding(
                                  padding: const EdgeInsets.only(left: AppSpacing.md),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Iliyotolewa',
                                            style: AppTextStyles.caption.copyWith(
                                                color: Colors.white
                                                    .withValues(alpha: 0.6))),
                                        const SizedBox(height: 4),
                                        Text(
                                          _balanceVisible
                                              ? 'TZS ${_formatPrice(_wallet?['total_disbursed'] ?? 0)}'
                                              : 'TZS ••••',
                                          style: AppTextStyles.buttonLarge.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white),
                                        ),
                                      ]),
                                )),
                              ]),
                              const SizedBox(height: AppSpacing.lg),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFFE87722),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(AppSpacing.sm + AppSpacing.xs)),
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                  ),
                                  onPressed: _showWithdrawSheet,
                                  child: Text('Omba Malipo',
                                      style: AppTextStyles.buttonMedium.copyWith(
                                          color: const Color(0xFFE87722))),
                                ),
                              ),
                            ]),
                      ),
                    ),

                    // ── TAB BAR ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg - AppSpacing.xs,
                        0,
                        AppSpacing.lg - AppSpacing.xs,
                        AppSpacing.sm,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A1A0A)
                              : const Color(0xFFF5E6D8),
                          borderRadius: BorderRadius.circular(AppSpacing.sm + AppSpacing.xs),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: const Color(0xFFE87722),
                            borderRadius: BorderRadius.circular(AppSpacing.sm + AppSpacing.xs / 2),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          unselectedLabelStyle: AppTextStyles.bodySmall,
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xFF7B3A10),
                          dividerColor: Colors.transparent,
                          tabs: [
                            Tab(text: 'Zilizokamilika (${successful.length})'),
                            Tab(text: 'Zinasubiri (${pending.length})'),
                          ],
                        ),
                      ),
                    ),

                    // ── TAB CONTENT ──
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildCheckoutList(
                              successful, 'Hakuna malipo yaliyokamilika bado.'),
                          _buildCheckoutList(
                              pending, 'Hakuna maombi yanayosubiri.'),
                        ],
                      ),
                    ),
                  ])),
      ),
    );
  }
}
