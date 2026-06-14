import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

enum _TransactionFilter {
  all('Zote'),
  successful('Zilizofaulu'),
  pending('Zinasubiri'),
  failed('Zilizoshindikana'),
  refunded('Zilizorejeshwa');

  const _TransactionFilter(this.label);

  final String label;
}

enum _TransactionStatus {
  successful,
  pending,
  failed,
  refunded,
}

class _UserTransaction {
  const _UserTransaction({
    required this.title,
    required this.contentType,
    required this.amount,
    required this.amountText,
    required this.method,
    required this.status,
    required this.date,
    required this.reference,
  });

  final String title;
  final String contentType;
  final double amount;
  final String amountText;
  final String method;
  final _TransactionStatus status;
  final DateTime? date;
  final String reference;

  String get searchableText => [
        title,
        contentType,
        method,
        reference,
        statusLabel,
        amountText,
      ].join(' ').toLowerCase();

  String get statusLabel {
    switch (status) {
      case _TransactionStatus.successful:
        return 'Imefaulu';
      case _TransactionStatus.pending:
        return 'Inasubiri';
      case _TransactionStatus.failed:
        return 'Imeshindikana';
      case _TransactionStatus.refunded:
        return 'Imerejeshwa';
    }
  }

  bool matches(_TransactionFilter filter) {
    switch (filter) {
      case _TransactionFilter.all:
        return true;
      case _TransactionFilter.successful:
        return status == _TransactionStatus.successful;
      case _TransactionFilter.pending:
        return status == _TransactionStatus.pending;
      case _TransactionFilter.failed:
        return status == _TransactionStatus.failed;
      case _TransactionFilter.refunded:
        return status == _TransactionStatus.refunded;
    }
  }
}

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _moneyFormatter = NumberFormat('#,###', 'en_US');
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');
  final DateFormat _dateTimeFormatter = DateFormat('dd MMM yyyy, HH:mm');

  List<_UserTransaction> _transactions = [];
  _TransactionFilter _selectedFilter = _TransactionFilter.all;
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient().dio.get('/api/v1/payments/checkout/');
      final data = res.data;
      final results = data is Map
          ? (data['results'] as List? ?? [])
          : (data as List? ?? []);
      final transactions = results
          .whereType<Map>()
          .map((item) => _mapTransaction(item.cast<String, dynamic>()))
          .toList()
        ..sort((a, b) {
          final left = a.date;
          final right = b.date;
          if (left == null && right == null) return 0;
          if (left == null) return 1;
          if (right == null) return -1;
          return right.compareTo(left);
        });

      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Hatukuweza kupakia miamala yako kwa sasa. Tafadhali jaribu tena.';
      });
    }
  }

  _UserTransaction _mapTransaction(Map<String, dynamic> payment) {
    final course = payment['course'];
    final ebook = payment['ebook'];
    final product = payment['product'];
    final contentMap = course is Map
        ? course
        : ebook is Map
            ? ebook
            : product is Map
                ? product
                : null;

    final title = _firstNonEmpty([
      if (contentMap != null) contentMap['title'],
      if (contentMap != null) contentMap['name'],
      payment['title'],
      payment['description'],
      'Ununuzi wa Karakana',
    ]);

    final contentType = _contentTypeFor(payment, course, ebook, product);
    final amount = _amountValue(payment['amount']);
    final paidAt = _parseDate(_firstNonEmpty([
      payment['paid_at'],
      payment['created_at'],
      payment['updated_at'],
      payment['initiated_at'],
    ]));

    return _UserTransaction(
      title: title,
      contentType: contentType,
      amount: amount,
      amountText: _formatPrice(payment['amount']),
      method: _formatMethod(payment['method']),
      status: _statusFor(payment),
      date: paidAt,
      reference: _firstNonEmpty([
        payment['external_id'],
        payment['reference'],
        payment['transaction_id'],
        payment['id'],
        '—',
      ]),
    );
  }

  String _contentTypeFor(
    Map<String, dynamic> payment,
    dynamic course,
    dynamic ebook,
    dynamic product,
  ) {
    final rawType = _firstNonEmpty([
      payment['content_type'],
      payment['item_type'],
      payment['type'],
    ]).toLowerCase();

    if (ebook is Map || rawType.contains('ebook')) return 'Ebook';
    if (course is Map || rawType.contains('course') || product is Map) {
      return 'Kozi';
    }
    return 'Huduma';
  }

  _TransactionStatus _statusFor(Map<String, dynamic> payment) {
    final rawStatus = _firstNonEmpty([
      payment['status'],
      payment['payment_status'],
      payment['state'],
    ]).toLowerCase();

    if (rawStatus.contains('refund') || rawStatus.contains('reversed')) {
      return _TransactionStatus.refunded;
    }
    if (rawStatus.contains('pending') ||
        rawStatus.contains('processing') ||
        rawStatus.contains('created')) {
      return _TransactionStatus.pending;
    }
    if (rawStatus.contains('fail') ||
        rawStatus.contains('cancel') ||
        rawStatus.contains('declin') ||
        rawStatus.contains('expired')) {
      return _TransactionStatus.failed;
    }

    if (payment['is_successful'] == true) {
      return _TransactionStatus.successful;
    }
    if (payment['is_successful'] == false) {
      return _TransactionStatus.failed;
    }
    if (payment['paid_at'] != null) {
      return _TransactionStatus.successful;
    }
    return _TransactionStatus.pending;
  }

  List<_UserTransaction> get _visibleTransactions {
    return _transactions.where((transaction) {
      final matchesFilter = transaction.matches(_selectedFilter);
      final matchesSearch = _searchQuery.isEmpty ||
          transaction.searchableText.contains(_searchQuery);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  double get _totalSpent => _transactions
      .where((item) => item.status == _TransactionStatus.successful)
      .fold(0, (total, item) => total + item.amount);

  int get _successfulCount => _transactions
      .where((item) => item.status == _TransactionStatus.successful)
      .length;

  int get _pendingCount => _transactions
      .where((item) => item.status == _TransactionStatus.pending)
      .length;

  String _formatPrice(dynamic price) {
    try {
      return 'TZS ${_moneyFormatter.format(double.parse(price.toString()))}';
    } catch (_) {
      return 'TZS $price';
    }
  }

  String _formatAmountValue(double amount) {
    return 'TZS ${_moneyFormatter.format(amount)}';
  }

  String _formatMethod(dynamic method) {
    final value = method?.toString().trim() ?? '';
    if (value.isEmpty) return 'Haijatajwa';
    return value
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tarehe haijatajwa';
    return _dateFormatter.format(date);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Tarehe haijatajwa';
    return _dateTimeFormatter.format(date);
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  double _amountValue(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: _isLoading
            ? const Center(child: KarakanaWaveLoader(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadPayments,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TransactionsHeaderDelegate(
                        topInset: MediaQuery.paddingOf(context).top,
                        onBack: _handleBack,
                      ),
                    ),
                    if (_errorMessage != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildErrorState(context),
                      )
                    else if (_transactions.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context),
                      )
                    else ...[
                      SliverToBoxAdapter(child: _buildSummarySection()),
                      SliverToBoxAdapter(child: _buildSearchAndFilters()),
                      if (_visibleTransactions.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildNoResultsState(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            AppSpacing.xl,
                          ),
                          sliver: SliverList.separated(
                            itemCount: _visibleTransactions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (_, index) => _TransactionCard(
                              transaction: _visibleTransactions[index],
                              dateText:
                                  _formatDate(_visibleTransactions[index].date),
                              onTap: () => _showTransactionDetails(
                                _visibleTransactions[index],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Widget _buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          _TotalSpentCard(totalText: _formatAmountValue(_totalSpent)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Zilizofaulu',
                  value: '$_successfulCount',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  label: 'Zinasubiri',
                  value: '$_pendingCount',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFFB86A00),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tafuta kwa kozi, ebook, njia au rejea',
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _TransactionFilter.values.map((filter) {
                final selected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    selected: selected,
                    label: Text(filter.label),
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter);
                    },
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                    selectedColor: AppColors.primaryDark,
                    backgroundColor: Theme.of(context).cardColor,
                    side: BorderSide(
                      color:
                          selected ? AppColors.primaryDark : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return _CenteredState(
      icon: Icons.receipt_long_outlined,
      title: 'Hakuna miamala bado',
      message:
          'Ukianza kununua kozi au ebook, historia ya malipo itaonekana hapa.',
      actionLabel: 'Tafuta Kozi',
      onAction: () => context.go('/home'),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return _CenteredState(
      icon: Icons.cloud_off_rounded,
      title: 'Imeshindikana kupakia',
      message: _errorMessage ??
          'Hatukuweza kupata historia yako ya malipo kwa sasa.',
      actionLabel: 'Jaribu Tena',
      onAction: _loadPayments,
    );
  }

  Widget _buildNoResultsState() {
    return _CenteredState(
      icon: Icons.manage_search_rounded,
      title: 'Hakuna matokeo',
      message:
          'Badili kichujio au neno la utafutaji ili kuona miamala mingine.',
      actionLabel: 'Futa Utafutaji',
      onAction: () {
        _searchController.clear();
        setState(() => _selectedFilter = _TransactionFilter.all);
      },
    );
  }

  void _showTransactionDetails(_UserTransaction transaction) {
    final statusStyle = _statusStyle(transaction.status);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.modal)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.circle),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusStyle.background,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Icon(statusStyle.icon, color: statusStyle.color),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.title,
                            style: AppTextStyles.h3.copyWith(
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color ??
                                  AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            transaction.contentType,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _DetailRow(label: 'Kiasi', value: transaction.amountText),
                _DetailRow(label: 'Hali', value: transaction.statusLabel),
                _DetailRow(label: 'Njia ya Malipo', value: transaction.method),
                _DetailRow(
                  label: 'Tarehe',
                  value: _formatDateTime(transaction.date),
                ),
                _DetailRow(label: 'Rejea', value: transaction.reference),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: Text(
                      'Sawa',
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
      },
    );
  }
}

class _TransactionsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TransactionsHeaderDelegate({
    required this.topInset,
    required this.onBack,
  });

  final double topInset;
  final VoidCallback onBack;

  @override
  double get minExtent => topInset + 64;

  @override
  double get maxExtent => topInset + 258;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final expandedOpacity = (1 - (progress * 1.35)).clamp(0.0, 1.0);
    final compactOpacity = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
    final bottomRadius = Radius.circular(AppRadius.modal * (1 - progress));

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: bottomRadius),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.lg,
            top: topInset + AppSpacing.sm,
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Opacity(
                      opacity: compactOpacity,
                      child: Text(
                        'Miamala Yangu',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: expandedOpacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Salama',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
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
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: topInset + 96 - (progress * 28),
            child: IgnorePointer(
              ignoring: progress > 0.45,
              child: Opacity(
                opacity: expandedOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Miamala Yangu',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Fuatilia malipo yako, hali ya ununuzi, na historia ya kozi au ebook ulizonunua.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TransactionsHeaderDelegate oldDelegate) {
    return topInset != oldDelegate.topInset || onBack != oldDelegate.onBack;
  }
}

class _TotalSpentCard extends StatelessWidget {
  const _TotalSpentCard({required this.totalText});

  final String totalText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jumla uliyolipa',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  totalText,
                  style: AppTextStyles.h1.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Malipo yaliyothibitishwa pekee',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.h3.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.dateText,
    required this.onTap,
  });

  final _UserTransaction transaction;
  final String dateText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(transaction.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.cardLg),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusStyle.background,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Icon(statusStyle.icon, color: statusStyle.color),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelLarge.copyWith(
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${transaction.contentType} • ${transaction.method}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        transaction.amountText,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(dateText, style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _StatusChip(transaction: transaction),
                  const Spacer(),
                  Text(
                    'Maelezo',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.primary,
                    size: 12,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.transaction});

  final _UserTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(transaction.status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: statusStyle.background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusStyle.icon, color: statusStyle.color, size: 14),
          const SizedBox(width: AppSpacing.xs),
          Text(
            transaction.statusLabel,
            style: AppTextStyles.labelSmall.copyWith(color: statusStyle.color),
          ),
        ],
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.cardLg),
            ),
            child: Icon(icon, size: 34, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h2.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color ??
                  AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              actionLabel,
              style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.labelMedium.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionStatusStyle {
  const _TransactionStatusStyle({
    required this.color,
    required this.background,
    required this.icon,
  });

  final Color color;
  final Color background;
  final IconData icon;
}

_TransactionStatusStyle _statusStyle(_TransactionStatus status) {
  switch (status) {
    case _TransactionStatus.successful:
      return const _TransactionStatusStyle(
        color: AppColors.primary,
        background: AppColors.primaryLight,
        icon: Icons.check_circle_outline_rounded,
      );
    case _TransactionStatus.pending:
      return const _TransactionStatusStyle(
        color: Color(0xFFB86A00),
        background: Color(0xFFFFF3D8),
        icon: Icons.schedule_rounded,
      );
    case _TransactionStatus.failed:
      return const _TransactionStatusStyle(
        color: AppColors.error,
        background: AppColors.errorLight,
        icon: Icons.error_outline_rounded,
      );
    case _TransactionStatus.refunded:
      return const _TransactionStatusStyle(
        color: Color(0xFF3F6B8F),
        background: Color(0xFFE7F3FC),
        icon: Icons.undo_rounded,
      );
  }
}
