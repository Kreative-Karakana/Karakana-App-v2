import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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

/// Shown wherever a premium action (create/edit/delete) is blocked because
/// the backend reports no active entitlement (issue #31). "Boresha Sasa"
/// hands off to the subscription status/upgrade screen (issue #33); this
/// dialog itself only explains why the action didn't happen and reassures
/// the user their existing data is safe.
Future<void> showSubscriptionRequiredDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Boresha Akaunti',
        style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
      ),
      content: Text(
        kSubscriptionRequiredMessage,
        style: GoogleFonts.montserrat(fontSize: 13, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            'Nimeelewa',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            _goToSubscription(context);
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(
            'Boresha Sasa',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

/// Navigates to the subscription screen (issue #33) and, once the user
/// comes back, re-syncs entitlement so a completed purchase/trial
/// immediately clears the read-only state here without waiting for the
/// next full [BusinessManagementProvider.loadInitial] call.
Future<void> _goToSubscription(BuildContext context) async {
  final provider = context.read<BusinessManagementProvider>();
  await context.push('/subscription');
  if (context.mounted) {
    await provider.loadInitial();
  }
}

/// Persistent, non-dismissible banner explaining the read-only state
/// (issue #31) — shown above the dashboard/setup-form content rather than
/// as a one-off toast, since it describes a standing condition, not a
/// single event.
class _ReadOnlyBanner extends StatelessWidget {
  final String message;

  const _ReadOnlyBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_clock_outlined,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _goToSubscription(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Boresha Akaunti →',
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
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
                        'Usimamizi wa Biashara hukusaidia kufuatilia Mauzo na '
                        'Matumizi ya biashara yako kwa urahisi, popote ulipo.',
                  ),
                  if (provider.isReadOnly) ...[
                    const SizedBox(height: 14),
                    const _ReadOnlyBanner(
                      message:
                          'Huna usajili amilifu kwa sasa, hivyo huwezi kuanzisha biashara mpya. '
                          'Boresha akaunti yako ili uanze.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  const SizedBox(height: 14),
                  const _HowItWorksCard(),
                  const SizedBox(height: 14),
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
                if (provider.isReadOnly) ...[
                  _ReadOnlyBanner(
                      message: provider.entitlement?.isExpired == true
                          ? 'Muda wa jaribio au usajili wako umeisha. Taarifa zako zipo salama — boresha akaunti yako ili kuendelea kuongeza au kuhariri.'
                          : 'Huna usajili amilifu kwa sasa. Taarifa zako zipo salama — boresha akaunti yako ili kuendelea kuongeza au kuhariri.'),
                  const SizedBox(height: 14),
                ],
                _BusinessHeader(
                  business: provider.business!,
                  onEdit: () => _openBusinessEditSheet(context),
                ),
                const SizedBox(height: 14),
                _DashboardSummary(provider: provider),
                if (provider.showFirstTransactionGuide) ...[
                  const SizedBox(height: 14),
                  _FirstTransactionGuide(
                    onDismiss: () => provider.dismissFirstTransactionGuide(),
                  ),
                ],
                const SizedBox(height: 14),
                _ActionRow(
                  onSale: () => _openTransactionSheet(context, isSale: true),
                  onExpense: () =>
                      _openTransactionSheet(context, isSale: false),
                  isLocked: provider.isReadOnly,
                ),
                const SizedBox(height: 18),
                _RecentTransactions(
                  provider: provider,
                  onEdit: (transaction) =>
                      _openTransactionSheet(context, transaction: transaction),
                  onDelete: _confirmAndDelete,
                  onRecordSale: () =>
                      _openTransactionSheet(context, isSale: true),
                  deletingTransactionId: _deletingTransactionId,
                ),
                const SizedBox(height: 18),
                _HistorySection(
                  provider: provider,
                  onEdit: (transaction) =>
                      _openTransactionSheet(context, transaction: transaction),
                  onDelete: _confirmAndDelete,
                  onRecordSale: () =>
                      _openTransactionSheet(context, isSale: true),
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
    if (context.read<BusinessManagementProvider>().isReadOnly) {
      return showSubscriptionRequiredDialog(context);
    }
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

  Future<void> _openBusinessEditSheet(BuildContext context) {
    if (context.read<BusinessManagementProvider>().isReadOnly) {
      return showSubscriptionRequiredDialog(context);
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<BusinessManagementProvider>(),
        child: const _BusinessEditSheet(),
      ),
    );
  }

  Future<void> _confirmAndDelete(BusinessTransaction transaction) async {
    if (context.read<BusinessManagementProvider>().isReadOnly) {
      await showSubscriptionRequiredDialog(context);
      return;
    }
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
    if (widget.provider.isReadOnly) {
      await showSubscriptionRequiredDialog(context);
      return;
    }

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
    final currency = provider.business?.currency ??
        provider.dashboardSummary?.currency ??
        'TZS';
    final hasTransactions = (provider.dashboardSummary?.miamala ?? 0) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Muhtasari',
          subtitle: hasTransactions
              ? 'Takwimu za leo na mwezi huu.'
              : 'Nambari hizi zitasasishwa kila ukirekodi Mauzo au Matumizi.',
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
                  isPositive: todayTotals.hasProfit,
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
                  isPositive: monthTotals.hasProfit,
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
  final bool isLocked;

  const _ActionRow({
    required this.onSale,
    required this.onExpense,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.add_circle_outline,
            label: 'Rekodi Mauzo',
            onTap: onSale,
            isLocked: isLocked,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.remove_circle_outline,
            label: 'Rekodi Matumizi',
            onTap: onExpense,
            isLocked: isLocked,
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
  final VoidCallback onRecordSale;
  final int? deletingTransactionId;

  const _RecentTransactions({
    required this.provider,
    required this.onEdit,
    required this.onDelete,
    required this.onRecordSale,
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
            _EmptyState(
              title: 'Hakuna miamala bado',
              message: 'Rekodi Mauzo au Matumizi ili yaonekane hapa.',
              actionLabel: 'Rekodi Mauzo',
              onAction: onRecordSale,
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

class _HistorySection extends StatefulWidget {
  final BusinessManagementProvider provider;
  final ValueChanged<BusinessTransaction> onEdit;
  final ValueChanged<BusinessTransaction> onDelete;
  final VoidCallback onRecordSale;
  final int? deletingTransactionId;

  const _HistorySection({
    required this.provider,
    required this.onEdit,
    required this.onDelete,
    required this.onRecordSale,
    this.deletingTransactionId,
  });

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.provider.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _HistorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = widget.provider.searchQuery;
    if (_searchController.text != query) {
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      widget.provider.loadTransactions(search: value);
    });
  }

  Future<void> _openFilterSheet() async {
    final provider = widget.provider;
    final result = await showModalBottomSheet<_TransactionFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionFilterSheet(
        initial: _TransactionFilterResult(
          transactionType: provider.selectedTransactionType,
          category: provider.selectedCategory,
          dateFrom: provider.dateFrom,
          dateTo: provider.dateTo,
          ordering: provider.ordering,
        ),
      ),
    );
    if (result == null) return;
    await provider.applyFilters(
      transactionType: result.transactionType,
      category: result.category,
      dateFrom: result.dateFrom,
      dateTo: result.dateTo,
      search: provider.searchQuery,
      ordering: result.ordering,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Historia ya Miamala',
            subtitle: 'Tafuta na chuja Mauzo na Matumizi yako.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.montserrat(fontSize: 13),
                  decoration: _inputDecoration(
                    'Tafuta muamala',
                    'k.m. jina la mteja, maelezo...',
                  ).copyWith(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FilterIconButton(
                active: provider.selectedCategory != null ||
                    provider.dateFrom != null ||
                    provider.dateTo != null ||
                    provider.ordering != null,
                onTap: _openFilterSheet,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'Yote',
                selected: provider.selectedTransactionType == null,
                onTap: () => provider.setTransactionType(null),
              ),
              _FilterChip(
                label: 'Mauzo',
                selected: provider.selectedTransactionType == 'sale',
                onTap: () => provider.setTransactionType('sale'),
              ),
              _FilterChip(
                label: 'Matumizi',
                selected: provider.selectedTransactionType == 'expense',
                onTap: () => provider.setTransactionType('expense'),
              ),
            ],
          ),
          if (provider.hasActiveFilters) ...[
            const SizedBox(height: 10),
            _ActiveFiltersBar(provider: provider),
          ],
          const SizedBox(height: 12),
          if (provider.isLoadingTransactions)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: KarakanaWaveLoader(size: 28)),
            )
          else if (provider.transactions.isEmpty)
            provider.hasActiveFilters
                ? const _EmptyState(
                    title: 'Hakuna miamala inayolingana',
                    message:
                        'Jaribu kubadilisha vichujio au neno la utafutaji, '
                        'au gusa "Futa Vichujio" kuona miamala yote.',
                  )
                : _EmptyState(
                    title: 'Hakuna historia bado',
                    message: 'Miamala utakayorekodi itaonekana hapa.',
                    actionLabel: 'Rekodi Mauzo',
                    onAction: widget.onRecordSale,
                  )
          else ...[
            ...provider.transactions.map(
              (item) => _TransactionTile(
                transaction: item,
                onTap: () => widget.onEdit(item),
                onDelete: () => widget.onDelete(item),
                isDeleting: widget.deletingTransactionId == item.id,
              ),
            ),
            _HistoryPaginationFooter(provider: provider),
          ],
        ],
      ),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _FilterIconButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: active ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.primaryDark : AppColors.inputBorder,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 20,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
            if (active)
              Positioned(
                top: 8,
                right: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  final BusinessManagementProvider provider;

  const _ActiveFiltersBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (provider.selectedCategory != null) {
      chips.add(
        _RemovableChip(
          label: _categoryLabel(provider.selectedCategory!),
          onRemoved: () => provider.applyFilters(
            transactionType: provider.selectedTransactionType,
            dateFrom: provider.dateFrom,
            dateTo: provider.dateTo,
            search: provider.searchQuery,
            ordering: provider.ordering,
          ),
        ),
      );
    }
    if (provider.dateFrom != null || provider.dateTo != null) {
      final from = provider.dateFrom;
      final to = provider.dateTo;
      final label = from != null && to != null
          ? '${_formatDate(from)} - ${_formatDate(to)}'
          : from != null
              ? 'Tangu ${_formatDate(from)}'
              : 'Hadi ${_formatDate(to)}';
      chips.add(
        _RemovableChip(
          label: label,
          onRemoved: () => provider.applyFilters(
            transactionType: provider.selectedTransactionType,
            category: provider.selectedCategory,
            search: provider.searchQuery,
            ordering: provider.ordering,
          ),
        ),
      );
    }
    if (provider.ordering != null) {
      chips.add(
        _RemovableChip(
          label: _sortLabel(provider.ordering!),
          onRemoved: () => provider.applyFilters(
            transactionType: provider.selectedTransactionType,
            category: provider.selectedCategory,
            dateFrom: provider.dateFrom,
            dateTo: provider.dateTo,
            search: provider.searchQuery,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...chips,
        TextButton.icon(
          onPressed: provider.resetFilters,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
          label: Text(
            'Futa Vichujio',
            style: GoogleFonts.montserrat(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemoved;

  const _RemovableChip({required this.label, required this.onRemoved});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 11, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: AppColors.primaryDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemoved,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionFilterResult {
  final String? transactionType;
  final String? category;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? ordering;

  const _TransactionFilterResult({
    this.transactionType,
    this.category,
    this.dateFrom,
    this.dateTo,
    this.ordering,
  });
}

class _TransactionFilterSheet extends StatefulWidget {
  final _TransactionFilterResult initial;

  const _TransactionFilterSheet({required this.initial});

  @override
  State<_TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<_TransactionFilterSheet> {
  late String? _transactionType;
  late String _category;
  late DateTime? _dateFrom;
  late DateTime? _dateTo;
  late String _ordering;

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initial.transactionType;
    _category = widget.initial.category ?? '';
    _dateFrom = widget.initial.dateFrom;
    _dateTo = widget.initial.dateTo;
    _ordering = widget.initial.ordering ?? '';
  }

  Map<String, String> get _categoryOptions {
    final Map<String, String> options = {'': 'Zote'};
    if (_transactionType == 'sale') {
      options.addAll(_saleCategories);
    } else if (_transactionType == 'expense') {
      options.addAll(_expenseCategories);
    } else {
      options.addAll(_saleCategories);
      options.addAll(_expenseCategories);
    }
    return options;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
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
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _dateFrom = picked;
      } else {
        _dateTo = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                'Chuja Miamala',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aina',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'Yote',
                    selected: _transactionType == null,
                    onTap: () => setState(() {
                      _transactionType = null;
                      _category = '';
                    }),
                  ),
                  _FilterChip(
                    label: 'Mauzo',
                    selected: _transactionType == 'sale',
                    onTap: () => setState(() {
                      _transactionType = 'sale';
                      _category = '';
                    }),
                  ),
                  _FilterChip(
                    label: 'Matumizi',
                    selected: _transactionType == 'expense',
                    onTap: () => setState(() {
                      _transactionType = 'expense';
                      _category = '';
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _KarakanaDropdown(
                label: 'Aina ndogo (Category)',
                value: _category,
                items: _categoryOptions,
                onChanged: (value) => setState(() => _category = value ?? ''),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _OptionalDateField(
                      label: 'Kuanzia tarehe',
                      date: _dateFrom,
                      onTap: () => _pickDate(isFrom: true),
                      onClear: () => setState(() => _dateFrom = null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OptionalDateField(
                      label: 'Hadi tarehe',
                      date: _dateTo,
                      onTap: () => _pickDate(isFrom: false),
                      onClear: () => setState(() => _dateTo = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _KarakanaDropdown(
                label: 'Panga kwa',
                value: _ordering,
                items: _sortOptions,
                onChanged: (value) => setState(() => _ordering = value ?? ''),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _transactionType = null;
                        _category = '';
                        _dateFrom = null;
                        _dateTo = null;
                        _ordering = '';
                      }),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.inputBorder),
                      ),
                      child: Text(
                        'Futa Vichujio',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PrimaryButton(
                      label: 'Tumia Vichujio',
                      isLoading: false,
                      onPressed: () => Navigator.pop(
                        context,
                        _TransactionFilterResult(
                          transactionType: _transactionType,
                          category: _category.isEmpty ? null : _category,
                          dateFrom: _dateFrom,
                          dateTo: _dateTo,
                          ordering: _ordering.isEmpty ? null : _ordering,
                        ),
                      ),
                    ),
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

class _OptionalDateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _OptionalDateField({
    required this.label,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(label, 'Chagua tarehe').copyWith(
          suffixIcon: date == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: onClear,
                ),
        ),
        child: Text(
          date == null ? 'Chagua tarehe' : _formatDate(date),
          style: GoogleFonts.montserrat(
            color: date == null ? AppColors.textHint : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
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

class _BusinessEditSheet extends StatefulWidget {
  const _BusinessEditSheet();

  @override
  State<_BusinessEditSheet> createState() => _BusinessEditSheetState();
}

class _BusinessEditSheetState extends State<_BusinessEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _businessType;

  @override
  void initState() {
    super.initState();
    final business = context.read<BusinessManagementProvider>().business;
    _nameController = TextEditingController(text: business?.name ?? '');
    _businessType = business?.businessType ?? _businessTypes.keys.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessManagementProvider>();

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
                const _SectionTitle(
                  title: 'Hariri Biashara',
                  subtitle: 'Sasisha jina au aina ya biashara yako.',
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
                    label: 'Hifadhi Mabadiliko',
                    isLoading: provider.isSubmitting,
                    onPressed: () => _submit(provider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BusinessManagementProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await provider.updateBusiness(
      name: _nameController.text.trim(),
      businessType: _businessType,
    );

    if (!mounted) return;
    if (ok) {
      showTopPopup(
        context,
        'Taarifa za biashara zimesasishwa.',
        type: TopPopupType.success,
      );
      Navigator.of(context).pop();
    } else {
      showTopPopup(
        context,
        provider.errorMessage ?? 'Imeshindikana kusasisha biashara.',
        type: TopPopupType.error,
      );
    }
  }
}

class _BusinessHeader extends StatelessWidget {
  final Business business;
  final VoidCallback? onEdit;

  const _BusinessHeader({required this.business, this.onEdit});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
          ),
          if (onEdit != null)
            Material(
              color: Colors.white.withValues(alpha: 0.16),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onEdit,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
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

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  static const _steps = [
    ('1', 'Weka jina na aina ya biashara yako.'),
    ('2', 'Rekodi Mauzo na Matumizi unapotokea.'),
    ('3', 'Ona Faida au Hasara yako papo kwa hapo.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Jinsi inavyofanya kazi'),
          const SizedBox(height: 12),
          for (final step in _steps) ...[
            _StepRow(number: step.$1, text: step.$2),
            if (step != _steps.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: GoogleFonts.montserrat(
              color: AppColors.primaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FirstTransactionGuide extends StatelessWidget {
  final VoidCallback onDismiss;

  const _FirstTransactionGuide({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 20,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hatua inayofuata',
                  style: GoogleFonts.montserrat(
                    color: AppColors.primaryDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Rekodi Mauzo au Matumizi yako ya kwanza hapa chini ili '
                  'uanze kuona takwimu za biashara yako.',
                  style: GoogleFonts.montserrat(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
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
  final bool isPositive;

  const _MetricCard({
    required this.label,
    required this.value,
    this.isNegative = false,
    this.isPositive = false,
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
                color: isNegative
                    ? AppColors.error
                    : isPositive
                        ? AppColors.profit
                        : AppColors.primaryDark,
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
  final bool isLocked;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isLocked ? AppColors.textSecondary : AppColors.primary;
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
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: isLocked
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isLocked)
                const Icon(
                  Icons.lock_outline,
                  size: 15,
                  color: AppColors.textSecondary,
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
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.primaryDark,
              ),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: Text(
                actionLabel!,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
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

String _sortLabel(String value) => _sortOptions[value] ?? value;

const Map<String, String> _sortOptions = {
  '': 'Tarehe (Mpya kwanza)',
  'transaction_date': 'Tarehe (Zamani kwanza)',
  '-amount': 'Kiasi (Kikubwa kwanza)',
  'amount': 'Kiasi (Kidogo kwanza)',
};

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
