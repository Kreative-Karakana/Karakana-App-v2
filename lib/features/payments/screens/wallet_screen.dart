import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _wallet;
  List<dynamic> _checkouts = [];
  bool _isLoading = true;
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
      final checkoutRes = await ApiClient().dio.get('/api/v1/wallet/checkouts/');
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5C8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Omba Malipo',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3B1A08),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kiasi cha Kutoa',
                prefixIcon: const Icon(
                  Icons.payments_outlined,
                  color: Color(0xFFC4620A),
                ),
                filled: true,
                fillColor: const Color(0xFFFFF8F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFC4620A),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarkController,
              decoration: InputDecoration(
                labelText: 'Maelezo (hiari)',
                prefixIcon: const Icon(
                  Icons.notes_outlined,
                  color: Color(0xFFC4620A),
                ),
                filled: true,
                fillColor: const Color(0xFFFFF8F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFC4620A),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC4620A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: () async {
                  try {
                    await ApiClient().dio.post(
                      '/api/v1/wallet/checkouts/',
                      data: {
                        'amount': _amountController.text,
                        'remark': _remarkController.text,
                      },
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    _amountController.clear();
                    _remarkController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ombi limetumwa kikamilifu!'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                    _loadWallet();
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hitilafu. Jaribu tena.'),
                        backgroundColor: Color(0xFFB71C1C),
                      ),
                    );
                  }
                },
                child: Text(
                  'Tuma Ombi',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF3B1A08)),
        title: Text(
          'Mkoba Wangu',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3B1A08),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC4620A)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF3B1A08),
                          Color(0xFF6B2E0A),
                          Color(0xFFC4620A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC4620A).withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Salio Linalopatikana',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color:
                                        Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'TZS ${_formatPrice(_wallet?['balance'] ?? 0)}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mapato Yote',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'TZS ${_formatPrice(_wallet?['total_income'] ?? 0)}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Iliyotolewa',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        color: Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'TZS ${_formatPrice(_wallet?['total_disbursed'] ?? 0)}',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFC4620A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            onPressed: _showWithdrawSheet,
                            child: Text(
                              'Omba Malipo',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFC4620A),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Historia ya Malipo',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3B1A08),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_checkouts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Hakuna historia ya malipo bado.',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: const Color(0xFF9E8070),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._checkouts.map((c) {
                      final checkout = c as Map;
                      final isSuccessful = checkout['is_successful'] == true;
                      final remark = checkout['remark'] as String? ?? '';
                      final amount = checkout['amount'];
                      final date = checkout['initiated_at'] as String? ?? '';
                      String formattedDate = '';
                      try {
                        formattedDate =
                            DateFormat('dd MMM yyyy').format(DateTime.parse(date));
                      } catch (_) {
                        formattedDate = date;
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSuccessful
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFF0E6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isSuccessful
                                    ? Icons.arrow_upward_rounded
                                    : Icons.pending_outlined,
                                color: isSuccessful
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFE65100),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    remark.isEmpty ? 'Ombi la Malipo' : remark,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF3B1A08),
                                    ),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      color: const Color(0xFF9E8070),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isSuccessful ? '-' : '~'}TZS ${_formatPrice(amount)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isSuccessful
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
