import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/common/karakana_wave_loader.dart';
import '../../../../widgets/common/top_popup.dart';
import '../models/business.dart';
import '../models/business_dashboard_summary.dart';
import '../models/business_transaction.dart';
import '../providers/business_management_provider.dart';

class BusinessManagementScreen extends StatelessWidget {
  const BusinessManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BusinessManagementProvider()..loadInitial(),
      child: const _BusinessManagementView(),
    );
  }
}

class _BusinessManagementView extends StatefulWidget {
  const _BusinessManagementView();

  @override
  State<_BusinessManagementView> createState() =>
      _BusinessManagementViewState();
}

class _BusinessManagementViewState extends State<_BusinessManagementView> {
  String? _historyFilter;
  int? _deletingTransactionId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMoreTransactions);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMoreTransactions() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.extentAfter > 480) return;
    context.read<BusinessManagementProvider>().loadMoreTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Text(
          'Usimamizi wa Biashara',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Consumer<BusinessManagementProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const _LoadingState(label: 'Inapakia taarifa...');
          }

          final error = provider.errorMessage;
          if (error != null && error.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              showTopPopup(context, error, type: TopPopupType.error);
              provider.clearError();
            });
          }

          if (provider.hasNoBusiness || provider.business == null) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: provider.loadInitial,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                children: [
                  const _HeaderPanel(
                    title: 'Anza na biashara yako',
                    subtitle:
                        'Weka jina na aina ya biashara ili uanze kurekodi Mauzo na Matumizi.',
                  ),
                  const SizedBox(height: 16),
                  _BusinessSetupCard(provider: provider),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: provider.loadInitial,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                _BusinessHeader(business: provider.business!),
                const SizedBox(height: 14),
                _DashboardSummary(provider: provider),
                const SizedBox(height: 14),
                _ActionRow(
                  onSale: () => _openTransactionSheet(context, isSale: true),
                  onExpense: () =>
                      _openTransactionSheet(context, isSale: false),
                ),
                const SizedBox(height: 18),
                _RecentTransactions(
                  provider: provider,
                  onEdit: (transaction) =>
                      _openTransactionSheet(context, transaction: transaction),
                  onDelete: _confirmAndDelete,
                  deletingTransactionId: _deletingTransactionId,
                ),
                const SizedBox(height: 18),
                _HistorySection(
                  provider: provider,
                  filter: _historyFilter,
                  onFilterChanged: (value) async {
                    setState(() => _historyFilter = value);
                    provider.clearFilters();
                    await provider.loadTransactions(transactionType: value);
                  },
                  onEdit: (transaction) =>
                      _openTransactionSheet(context, transaction: transaction),
                  onDelete: _confirmAndDelete,
                  deletingTransactionId: _deletingTransactionId,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openTransactionSheet(
    BuildContext context, {
    bool isSale = true,
    BusinessTransaction? transaction,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<BusinessManagementProvider>(),
        child: _TransactionFormSheet(
          isSale: transaction?.isSale ?? isSale,
          transaction: transaction,
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BusinessTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Futa Muamala?',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Una uhakika unataka kufuta muamala huu wa ${transaction.typeLabel}? '
          'Hatua hii haiwezi kutenduliwa.',
          style: GoogleFonts.montserrat(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Ghairi',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
            ),
            child: Text(
              'Futa',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingTransactionId = transaction.id);
    final provider = context.read<BusinessManagementProvider>();
    final ok = await provider.deleteTransaction(transaction.id);

    if (!mounted) return;
    setState(() => _deletingTransactionId = null);

    if (ok) {
      showTopPopup(context, 'Muamala umefutwa.', type: TopPopupType.success);
    } else {
      showTopPopup(
        context,
        provider.errorMessage ?? 'Imeshindikana kufuta muamala.',
        type: TopPopupType.error,
      );
    }
  }
}

class _BusinessSetupCard extends StatefulWidget {
  final BusinessManagementProvider provider;

  const _BusinessSetupCard({required this.provider});

  @override
  State<_BusinessSetupCard> createState() => _BusinessSetupCardState();
}

class _BusinessSetupCardState extends State<_BusinessSetupCard> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _businessType = 'kinyozi';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'Taarifa za biashara',
              subtitle: 'MVP inasaidia biashara moja kwa sasa.',
            ),
            const SizedBox(height: 16),
            _KarakanaTextField(
              controller: _nameController,
              label: 'Jina la biashara',
              hint: 'Mfano: Kinyozi cha Mtaa',
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Weka jina la biashara.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _KarakanaDropdown(
              label: 'Aina ya biashara',
              value: _businessType,
              items: _businessTypes,
              onChanged: (value) {
                if (value != null) setState(() => _businessType = value);
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: _PrimaryButton(
                label: 'Hifadhi na endelea',
                isLoading: widget.provider.isSubmitting,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await widget.provider.createBusiness(
      name: _nameController.text.trim(),
      businessType: _businessType,
    );

    if (!mounted) return;
    if (ok) {
      showTopPopup(
        context,
        'Biashara imehifadhiwa.',
        type: TopPopupType.success,
      );
    } else {
      showTopPopup(
        context,
        widget.provider.errorMessage ?? 'Imeshindikana kuhifadhi biashara.',
        type: TopPopupType.error,
      );
    }
  }
}

class _DashboardSummary extends StatelessWidget {
  final BusinessManagementProvider provider;

  const _DashboardSummary({required this.provider});

  @override
  Widget build(BuildContext context) {
    final todayTotals =
        provider.dashboardSummary?.today ?? BusinessPeriodSummary.zero;
    final monthTotals =
        provider.dashboardSummary?.month ?? BusinessPeriodSummary.zero;
    final currency =
        provider.business?.currency ??
        provider.dashboardSummary?.currency ??
        'TZS';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Muhtasari',
          subtitle: 'Takwimu za leo na mwezi huu.',
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 680 ? 3 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: columns == 3 ? 2.0 : 1.35,
              children: [
                _MetricCard(
                  label: 'Mauzo ya Leo',
                  value: _money(todayTotals.mauzoValue, currency),
                ),
                _MetricCard(
                  label: 'Matumizi ya Leo',
                  value: _money(todayTotals.matumiziValue, currency),
                ),
                _MetricCard(
                  label: 'Faida / Hasara ya Leo',
                  value: _money(todayTotals.faidaHasaraValue, currency),
                  isNegative: todayTotals.hasLoss,
                ),
                _MetricCard(
                  label: 'Mauzo ya Mwezi',
                  value: _money(monthTotals.mauzoValue, currency),
                ),
                _MetricCard(
                  label: 'Matumizi ya Mwezi',
                  value: _money(monthTotals.matumiziValue, currency),
                ),
                _MetricCard(
                  label: 'Faida / Hasara ya Mwezi',
                  value: _money(monthTotals.faidaHasaraValue, currency),
                  isNegative: monthTotals.hasLoss,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onSale;
  final VoidCallback onExpense;

  const _ActionRow({required this.onSale, required this.onExpense});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.add_circle_outline,
            label: 'Rekodi Mauzo',
            onTap: onSale,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.remove_circle_outline,
            label: 'Rekodi Matumizi',
            onTap: onExpense,
          ),
        ),
      ],
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  final BusinessManagementProvider provider;
  final ValueChanged<BusinessTransaction> onEdit;
  final ValueChanged<BusinessTransaction> onDelete;
  final int? deletingTransactionId;

  const _RecentTransactions({
    required this.provider,
    required this.onEdit,
    required this.onDelete,
    this.deletingTransactionId,
  });

  @override
  Widget build(BuildContext context) {
    final recent =
        provider.dashboardSummary?.recentTransactions.isNotEmpty == true
        ? provider.dashboardSummary!.recentTransactions
        : provider.transactions.take(5).toList();

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Miamala ya karibuni',
            subtitle: 'Mauzo na Matumizi yaliyorekodiwa hivi karibuni.',
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            const _EmptyState(
              title: 'Hakuna miamala bado',
              message: 'Rekodi Mauzo au Matumizi ili yaonekane hapa.',
            )
          else
            ...recent.map(
              (item) => _TransactionTile(
                transaction: item,
                onTap: () => onEdit(item),
                onDelete: () => onDelete(item),
                isDeleting: deletingTransactionId == item.id,
              ),
            ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final BusinessManagementProvider provider;
  final String? filter;
  final ValueChanged<String?> onFilterChanged;
  final ValueChanged<BusinessTransaction> onEdit;
  final ValueChanged<BusinessTransaction> onDelete;
  final int? deletingTransactionId;

  const _HistorySection({
    required this.provider,
    required this.filter,
    required this.onFilterChanged,
    required this.onEdit,
    required this.onDelete,
    this.deletingTransactionId,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Historia ya Miamala',
            subtitle: 'Angalia Mauzo na Matumizi yote.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'Yote',
                selected: filter == null,
                onTap: () => onFilterChanged(null),
              ),
              _FilterChip(
                label: 'Mauzo',
                selected: filter == 'sale',
                onTap: () => onFilterChanged('sale'),
              ),
              _FilterChip(
                label: 'Matumizi',
                selected: filter == 'expense',
                onTap: () => onFilterChanged('expense'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.isLoadingTransactions)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: KarakanaWaveLoader(size: 28)),
            )
          else if (provider.transactions.isEmpty)
            const _EmptyState(
              title: 'Hakuna historia bado',
              message: 'Miamala utakayorekodi itaonekana hapa.',
            )
          else ...[
            ...provider.transactions.map(
              (item) => _TransactionTile(
                transaction: item,
                onTap: () => onEdit(item),
                onDelete: () => onDelete(item),
                isDeleting: deletingTransactionId == item.id,
              ),
            ),
            _HistoryPaginationFooter(provider: provider),
          ],
        ],
      ),
    );
  }
}

class _HistoryPaginationFooter extends StatelessWidget {
  final BusinessManagementProvider provider;

  const _HistoryPaginationFooter({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingMoreTransactions) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: KarakanaWaveLoader(size: 24)),
      );
    }

    if (provider.loadMoreTransactionsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton.icon(
            onPressed: provider.loadMoreTransactions,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Jaribu tena',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }

    if (!provider.hasMoreTransactions) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(
            'Umefika mwisho wa historia',
            style: GoogleFonts.montserrat(
              color: AppColors.textTertiary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _TransactionFormSheet extends StatefulWidget {
  final bool isSale;
  final BusinessTransaction? transaction;

  const _TransactionFormSheet({required this.isSale, this.transaction});

  bool get isEditing => transaction != null;

  @override
  State<_TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<_TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final existing = widget.transaction;
    _category = existing?.category ?? (widget.isSale ? 'huduma' : 'kodi');
    _date = existing?.transactionDate ?? DateTime.now();
    _descriptionController.text = existing?.description ?? '';
    if (existing != null) {
      _amountController.text = _formatThousandsNumber(
        existing.amountValue.round().toString(),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessManagementProvider>();
    final isEditing = widget.isEditing;
    final recordLabel = widget.isSale ? 'Mauzo' : 'Matumizi';
    final title = isEditing ? 'Hariri $recordLabel' : 'Rekodi $recordLabel';
    final buttonLabel = isEditing ? 'Hifadhi Mabadiliko' : title;
    final categoryLabel = widget.isSale ? 'Aina ya Mauzo' : 'Aina ya Matumizi';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
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
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: title,
                  subtitle: isEditing
                      ? 'Unahariri muamala uliopo. Mabadiliko yatahifadhiwa baada ya kubonyeza Hifadhi Mabadiliko.'
                      : 'Jaza taarifa za muamala.',
                ),
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  _EditingBanner(recordLabel: recordLabel),
                ],
                const SizedBox(height: 16),
                _KarakanaTextField(
                  controller: _amountController,
                  label: 'Kiasi',
                  hint: 'Mfano: 15000',
                  keyboardType: TextInputType.number,
                  inputFormatters: const [_ThousandsSeparatorInputFormatter()],
                  validator: (value) {
                    final amount = int.tryParse(
                      _cleanAmount((value ?? '').trim()),
                    );
                    if (amount == null || amount <= 0) {
                      return 'Weka kiasi sahihi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _KarakanaDropdown(
                  label: categoryLabel,
                  value: _category,
                  items: widget.isSale ? _saleCategories : _expenseCategories,
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 12),
                _DatePickerField(
                  date: _date,
                  onChanged: (date) => setState(() => _date = date),
                ),
                const SizedBox(height: 12),
                _KarakanaTextField(
                  controller: _descriptionController,
                  label: 'Maelezo',
                  hint: 'Si lazima',
                  maxLines: 2,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: _PrimaryButton(
                    label: buttonLabel,
                    isLoading: provider.isSubmitting,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BusinessManagementProvider>();
    final amount = _cleanAmount(_amountController.text);
    final description = _descriptionController.text.trim();
    final existing = widget.transaction;
    final ok = existing != null
        ? await provider.updateTransaction(
            id: existing.id,
            amount: amount,
            category: _category,
            transactionDate: _date,
            description: description,
          )
        : widget.isSale
        ? await provider.createSale(
            amount: amount,
            category: _category,
            transactionDate: _date,
            description: description,
          )
        : await provider.createExpense(
            amount: amount,
            category: _category,
            transactionDate: _date,
            description: description,
          );

    if (!mounted) return;
    if (ok) {
      showTopPopup(
        context,
        existing != null
            ? 'Muamala umesasishwa.'
            : (widget.isSale
                  ? 'Mauzo yamerekodiwa.'
                  : 'Matumizi yamerekodiwa.'),
        type: TopPopupType.success,
      );
      Navigator.of(context).pop();
    } else {
      showTopPopup(
        context,
        provider.errorMessage ?? 'Imeshindikana kuhifadhi muamala.',
        type: TopPopupType.error,
      );
    }
  }
}

class _EditingBanner extends StatelessWidget {
  final String recordLabel;

  const _EditingBanner({required this.recordLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.edit_note_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unahariri $recordLabel yaliyokwisha rekodiwa.',
              style: GoogleFonts.montserrat(
                color: AppColors.primaryDark,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessHeader extends StatelessWidget {
  final Business business;

  const _BusinessHeader({required this.business});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            business.name,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_labelFor(_businessTypes, business.businessType)} • ${business.currency}',
            style: GoogleFonts.montserrat(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderPanel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.zanaGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.montserrat(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;

  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isNegative;

  const _MetricCard({
    required this.label,
    required this.value,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                color: isNegative ? AppColors.error : AppColors.primaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final BusinessTransaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isDeleting;

  const _TransactionTile({
    required this.transaction,
    this.onTap,
    this.onDelete,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSale = transaction.isSale;
    final color = isSale ? AppColors.primaryDark : AppColors.error;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSale ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${transaction.typeLabel} • ${_categoryLabel(transaction.category)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      _formatDate(transaction.transactionDate),
                      if (transaction.description.trim().isNotEmpty)
                        transaction.description.trim(),
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: AppColors.textTertiary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _money(transaction.amountValue, 'TZS'),
              style: GoogleFonts.montserrat(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              isDeleting
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: KarakanaWaveLoader(size: 16),
                      ),
                    )
                  : IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.error,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Futa muamala',
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KarakanaTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  const _KarakanaTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      style: GoogleFonts.montserrat(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(label, hint),
    );
  }
}

class _KarakanaDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _KarakanaDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.entries
          .map(
            (entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      onChanged: onChanged,
      style: GoogleFonts.montserrat(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(label, ''),
      borderRadius: BorderRadius.circular(12),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerField({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration('Tarehe ya muamala', ''),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Text(
              _formatDate(date),
              style: GoogleFonts.montserrat(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: isLoading
          ? const KarakanaWaveLoader(color: Colors.white, size: 20)
          : Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: GoogleFonts.montserrat(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: GoogleFonts.montserrat(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final String label;

  const _LoadingState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const KarakanaWaveLoader(size: 34),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String label, String hint) {
  return InputDecoration(
    labelText: label,
    hintText: hint.isEmpty ? null : hint,
    labelStyle: GoogleFonts.montserrat(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
    hintStyle: GoogleFonts.montserrat(
      color: AppColors.textHint,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.inputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error, width: 1.4),
    ),
  );
}

String _money(double value, String currency) {
  final normalized = value.abs() < 0.005 ? 0.0 : value;
  return '$currency ${_formatThousandsNumber(normalized.toStringAsFixed(0))}';
}

String _cleanAmount(String value) {
  return value.replaceAll(RegExp(r'[^0-9]'), '');
}

String _formatThousandsNumber(String digits) {
  final isNegative = digits.startsWith('-');
  final unsigned = isNegative ? digits.substring(1) : digits;
  final buffer = StringBuffer();

  for (var i = 0; i < unsigned.length; i++) {
    final remaining = unsigned.length - i;
    buffer.write(unsigned[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }

  return isNegative ? '-$buffer' : buffer.toString();
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const _ThousandsSeparatorInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _cleanAmount(newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final safeCursor = newValue.selection.extentOffset.clamp(
      0,
      newValue.text.length,
    );
    final digitsBeforeCursor = _cleanAmount(
      newValue.text.substring(0, safeCursor),
    ).length;
    final formatted = _formatThousands(digits);
    final cursorOffset = _offsetForDigitCount(formatted, digitsBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  static String _formatThousands(String digits) {
    return _formatThousandsNumber(digits);
  }

  static int _offsetForDigitCount(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;

    var seenDigits = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (_isDigit(formatted.codeUnitAt(i))) {
        seenDigits++;
      }
      if (seenDigits == digitCount) {
        return i + 1;
      }
    }
    return formatted.length;
  }

  static bool _isDigit(int codeUnit) {
    return codeUnit >= 48 && codeUnit <= 57;
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Tarehe haipo';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _labelFor(Map<String, String> items, String value) {
  return items[value] ?? value;
}

String _categoryLabel(String value) {
  return _saleCategories[value] ?? _expenseCategories[value] ?? value;
}

const Map<String, String> _businessTypes = {
  'kinyozi': 'Kinyozi',
  'saluni': 'Saluni',
  'mama_ntilie': 'Mama ntilie',
  'duka': 'Duka',
  'fundi': 'Fundi',
  'freelancer': 'Freelancer',
  'nyingine': 'Nyingine',
};

const Map<String, String> _saleCategories = {
  'huduma': 'Huduma',
  'bidhaa': 'Bidhaa',
  'nyingine': 'Nyingine',
};

const Map<String, String> _expenseCategories = {
  'kodi': 'Kodi',
  'umeme': 'Umeme',
  'maji': 'Maji',
  'usafiri': 'Usafiri',
  'malighafi': 'Malighafi',
  'mishahara': 'Mishahara',
  'matengenezo': 'Matengenezo',
  'nyingine': 'Nyingine',
};
