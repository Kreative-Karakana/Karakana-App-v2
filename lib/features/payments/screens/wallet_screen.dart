import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;
  String? _error;

  double _balance = 0;
  double _totalEarned = 0;
  double _totalWithdrawn = 0;

  Map<String, dynamic>? _bankAccount;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.get('/api/v1/wallet/me/');
      final data = response.data as Map<String, dynamic>? ?? {};

      _balance = (data['balance'] as num?)?.toDouble() ?? 0;
      _totalEarned = (data['total_earned'] as num?)?.toDouble() ?? 0;
      _totalWithdrawn = (data['total_withdrawn'] as num?)?.toDouble() ?? 0;
      _bankAccount = data['bank_account'] as Map<String, dynamic>?;

      final checkouts = data['checkouts'];
      if (checkouts is List) {
        _transactions = checkouts.cast<Map<String, dynamic>>();
      } else {
        _transactions = [];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]},',
        );
    return formatted;
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

  String _maskAccount(String? number) {
    if (number == null || number.length < 4) return number ?? '****';
    return '**** **** ${number.substring(number.length - 4)}';
  }

  void _showWithdrawDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Withdrawal coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showEditBankDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bank account editing coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
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
          'My Wallet',
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
                onPressed: _fetchWallet,
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

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchWallet,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BalanceCard(
              balance: _balance,
              totalEarned: _totalEarned,
              totalWithdrawn: _totalWithdrawn,
              formatAmount: _formatAmount,
              onWithdraw: _showWithdrawDialog,
            ),
            const SizedBox(height: 24),
            Text(
              'Bank Account',
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            _BankAccountCard(
              bankAccount: _bankAccount,
              maskAccount: _maskAccount,
              onEdit: _showEditBankDialog,
            ),
            const SizedBox(height: 24),
            Text(
              'Transaction History',
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            _transactions.isEmpty
                ? _EmptyTransactions()
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final tx = _transactions[i];
                      final amount =
                          (tx['amount'] as num?)?.toDouble() ?? 0;
                      final date = _formatDate(tx['created_at']?.toString());
                      final isCredit =
                          (tx['transaction_type']?.toString() ?? '') ==
                              'credit';
                      return _TransactionTile(
                        amount: amount,
                        date: date,
                        isCredit: isCredit,
                        formatAmount: _formatAmount,
                      );
                    },
                  ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Balance card
// ─────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.formatAmount,
    required this.onWithdraw,
  });

  final double balance;
  final double totalEarned;
  final double totalWithdrawn;
  final String Function(double) formatAmount;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.dark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TZS ${formatAmount(balance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Total Earned',
                  value: 'TZS ${formatAmount(totalEarned)}',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _StatBox(
                  label: 'Total Withdrawn',
                  value: 'TZS ${formatAmount(totalWithdrawn)}',
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onWithdraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Withdraw Funds',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: alignEnd ? 16 : 0,
        right: alignEnd ? 0 : 16,
      ),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bank account card
// ─────────────────────────────────────────────

class _BankAccountCard extends StatelessWidget {
  const _BankAccountCard({
    required this.bankAccount,
    required this.maskAccount,
    required this.onEdit,
  });

  final Map<String, dynamic>? bankAccount;
  final String Function(String?) maskAccount;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    if (bankAccount == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No bank account linked',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: Text(
                  'Add',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bankName = bankAccount!['bank_name']?.toString() ?? 'Bank';
    final accountNumber = bankAccount!['account_number']?.toString();
    final holderName = bankAccount!['account_holder_name']?.toString() ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.account_balance_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bankName,
                    style: TextStyle(
                      color: AppColors.dark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    maskAccount(accountNumber),
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (holderName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      holderName,
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Transaction tile
// ─────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.amount,
    required this.date,
    required this.isCredit,
    required this.formatAmount,
  });

  final double amount;
  final String date;
  final bool isCredit;
  final String Function(double) formatAmount;

  @override
  Widget build(BuildContext context) {
    final color = isCredit ? AppColors.success : AppColors.error;
    final prefix = isCredit ? '+' : '-';
    final icon = isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          isCredit ? 'Credit' : 'Withdrawal',
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        subtitle: date.isNotEmpty
            ? Text(
                date,
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              )
            : null,
        trailing: Text(
          '$prefix TZS ${formatAmount(amount)}',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty transactions
// ─────────────────────────────────────────────

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.grey),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your earnings and withdrawals will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
