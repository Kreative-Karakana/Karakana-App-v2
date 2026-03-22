import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.get('/api/v1/payments/checkout/');
      final data = response.data;

      List<dynamic> raw;
      if (data is List) {
        raw = data;
      } else if (data is Map && data.containsKey('results')) {
        raw = data['results'] as List<dynamic>? ?? [];
      } else {
        raw = [];
      }

      setState(() {
        _payments = raw.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double get _totalSpent {
    return _payments
        .where((p) => p['is_successful'] == true)
        .fold(0.0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0));
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]},',
        );
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  String _formatMethod(String? method) {
    switch (method?.toLowerCase()) {
      case 'mpesa':
        return 'M-Pesa';
      case 'tigopesa':
      case 'tigo_pesa':
        return 'Tigo Pesa';
      case 'airtel':
      case 'airtel_money':
        return 'Airtel Money';
      case 'halopesa':
        return 'Halopesa';
      default:
        return method ?? 'Mobile Money';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Payment History',
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.dark),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_payments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: AppColors.lightOrange,
              ),
              const SizedBox(height: 16),
              Text(
                'No payments yet',
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your payment history will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Browse Courses',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _payments.length + 1, // +1 for the summary header
        itemBuilder: (context, i) {
          if (i == 0) {
            return _TotalSummary(
              total: _totalSpent,
              formatAmount: _formatAmount,
            );
          }
          final payment = _payments[i - 1];
          final course = payment['course'] as Map<String, dynamic>?;
          final courseTitle = course?['title']?.toString() ?? 'Unknown Course';
          final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
          final method = _formatMethod(payment['method']?.toString());
          final date = _formatDate(
            (payment['paid_at'] ?? payment['created_at'])?.toString(),
          );
          final isSuccessful = payment['is_successful'] as bool? ?? false;
          final status = payment['status']?.toString() ?? '';
          final isPending = !isSuccessful && status != 'failed';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PaymentCard(
              courseTitle: courseTitle,
              method: method,
              date: date,
              amount: amount,
              isSuccessful: isSuccessful,
              isPending: isPending,
              formatAmount: _formatAmount,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Total summary
// ─────────────────────────────────────────────

class _TotalSummary extends StatelessWidget {
  const _TotalSummary({required this.total, required this.formatAmount});

  final double total;
  final String Function(double) formatAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'Total Spent',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          Text(
            'TZS ${formatAmount(total)}',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Payment card
// ─────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.courseTitle,
    required this.method,
    required this.date,
    required this.amount,
    required this.isSuccessful,
    required this.isPending,
    required this.formatAmount,
  });

  final String courseTitle;
  final String method;
  final String date;
  final double amount;
  final bool isSuccessful;
  final bool isPending;
  final String Function(double) formatAmount;

  Color get _statusColor {
    if (isSuccessful) return Colors.green.shade600;
    if (isPending) return Colors.orange.shade700;
    return AppColors.error;
  }

  String get _statusLabel {
    if (isSuccessful) return 'Paid';
    if (isPending) return 'Pending';
    return 'Failed';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseTitle,
                    style: TextStyle(
                      color: AppColors.dark,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method,
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 11,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TZS ${formatAmount(amount)}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
