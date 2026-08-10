import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/common/karakana_wave_loader.dart';
import '../../../../widgets/common/top_popup.dart';
import '../models/business_debt.dart';
import '../providers/debt_management_provider.dart';
import '../services/debt_management_service.dart';
import '../widgets/business_confirmation_dialog.dart';

class DebtManagementScreen extends StatelessWidget {
  final String currency;
  final bool isReadOnly;
  final Future<void> Function() onLockedAction;
  final DebtManagementApi? service;

  const DebtManagementScreen({
    super.key,
    required this.currency,
    required this.isReadOnly,
    required this.onLockedAction,
    this.service,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DebtManagementProvider(service: service)..loadDebts(),
      child: _DebtManagementView(
        currency: currency,
        isReadOnly: isReadOnly,
        onLockedAction: onLockedAction,
      ),
    );
  }
}

class _DebtManagementView extends StatefulWidget {
  final String currency;
  final bool isReadOnly;
  final Future<void> Function() onLockedAction;

  const _DebtManagementView({
    required this.currency,
    required this.isReadOnly,
    required this.onLockedAction,
  });

  @override
  State<_DebtManagementView> createState() => _DebtManagementViewState();
}

class _DebtManagementViewState extends State<_DebtManagementView> {
  final ScrollController _scrollController = ScrollController();
  int? _activeDebtId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMoreWhenNeeded() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 420) {
      context.read<DebtManagementProvider>().loadMore();
    }
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
          'Madeni',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-debt-button'),
        onPressed: _openCreate,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: Icon(widget.isReadOnly ? Icons.lock_outline : Icons.add),
        label: Text('Ongeza Deni', style: AppTextStyles.buttonMedium),
      ),
      body: Consumer<DebtManagementProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.debts.isEmpty) {
            return const _DebtLoadingState();
          }

          if (provider.errorMessage != null && provider.debts.isEmpty) {
            return _DebtErrorState(
              message: provider.errorMessage!,
              onRetry: () => provider.loadDebts(
                status: provider.selectedStatus,
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.loadDebts(
              status: provider.selectedStatus,
            ),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _DebtHeader(
                      count: provider.count,
                      selectedStatus: provider.selectedStatus,
                      onStatusChanged: provider.setStatusFilter,
                    ),
                  ),
                ),
                if (provider.debts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _DebtEmptyState(
                      filtered: provider.selectedStatus != null,
                      onAdd: _openCreate,
                      onClearFilter: () => provider.setStatusFilter(null),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      96,
                    ),
                    sliver: SliverList.separated(
                      itemCount: provider.debts.length + 1,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index == provider.debts.length) {
                          return _PaginationFooter(provider: provider);
                        }
                        final debt = provider.debts[index];
                        return _DebtCard(
                          debt: debt,
                          currency: widget.currency,
                          isBusy: _activeDebtId == debt.id,
                          isReadOnly: widget.isReadOnly,
                          onEdit: () => _openEdit(debt),
                          onDelete: () => _deleteDebt(debt),
                          onMarkPaid: () => _markPaid(debt),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _guardWrite(Future<void> Function() action) async {
    if (widget.isReadOnly) {
      await widget.onLockedAction();
      return;
    }
    await action();
  }

  Future<void> _openCreate() {
    return _guardWrite(() => _openForm());
  }

  Future<void> _openEdit(BusinessDebt debt) {
    return _guardWrite(() => _openForm(debt: debt));
  }

  Future<void> _openForm({BusinessDebt? debt}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<DebtManagementProvider>(),
        child: _DebtFormSheet(debt: debt, currency: widget.currency),
      ),
    );
  }

  Future<void> _markPaid(BusinessDebt debt) {
    return _guardWrite(() async {
      setState(() => _activeDebtId = debt.id);
      final provider = context.read<DebtManagementProvider>();
      final ok = await provider.markPaid(debt.id);
      if (!mounted) return;
      setState(() => _activeDebtId = null);
      _showResult(
        ok,
        success: 'Deni limewekwa kuwa limelipwa.',
        fallback: 'Imeshindikana kubadilisha hali ya deni.',
      );
    });
  }

  Future<void> _deleteDebt(BusinessDebt debt) {
    return _guardWrite(() async {
      final confirmed = await showBusinessConfirmationDialog(
        context,
        title: 'Futa Deni?',
        message: 'Una uhakika unataka kufuta deni la ${debt.customerName}? '
            'Hatua hii haiwezi kutenduliwa.',
        confirmLabel: 'Futa',
        isDestructive: true,
      );
      if (!confirmed || !mounted) return;

      setState(() => _activeDebtId = debt.id);
      final provider = context.read<DebtManagementProvider>();
      final ok = await provider.deleteDebt(debt.id);
      if (!mounted) return;
      setState(() => _activeDebtId = null);
      _showResult(
        ok,
        success: 'Deni limefutwa.',
        fallback: 'Imeshindikana kufuta deni.',
      );
    });
  }

  void _showResult(
    bool ok, {
    required String success,
    required String fallback,
  }) {
    final provider = context.read<DebtManagementProvider>();
    showTopPopup(
      context,
      ok ? success : (provider.errorMessage ?? fallback),
      type: ok ? TopPopupType.success : TopPopupType.error,
    );
    if (!ok) provider.clearError();
  }
}

class _DebtHeader extends StatelessWidget {
  final int count;
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  const _DebtHeader({
    required this.count,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Madeni ya Wateja', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Fuatilia wateja wanaodaiwa na madeni yaliyolipwa. Jumla: $count',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _StatusChip(
              key: const Key('debt-filter-all'),
              label: 'Yote',
              selected: selectedStatus == null,
              onTap: () => onStatusChanged(null),
            ),
            _StatusChip(
              key: const Key('debt-filter-outstanding'),
              label: 'Hayajalipwa',
              selected: selectedStatus == 'outstanding',
              onTap: () => onStatusChanged('outstanding'),
            ),
            _StatusChip(
              key: const Key('debt-filter-paid'),
              label: 'Yamelipwa',
              selected: selectedStatus == 'paid',
              onTap: () => onStatusChanged('paid'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: ExcludeSemantics(
              child: Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final BusinessDebt debt;
  final String currency;
  final bool isBusy;
  final bool isReadOnly;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarkPaid;

  const _DebtCard({
    required this.debt,
    required this.currency,
    required this.isBusy,
    required this.isReadOnly,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = debt.isPaid ? AppColors.profit : AppColors.primary;
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: debt.isOutstanding
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.customerName, style: AppTextStyles.h4),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _money(debt.amountValue, currency),
                        style: AppTextStyles.price,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    debt.statusLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (debt.itemService.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _DetailRow(
                icon: Icons.inventory_2_outlined,
                text: debt.itemService,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                _DateLabel(
                  label: 'Imetolewa',
                  date: debt.dateGiven,
                ),
                if (debt.dueDate != null)
                  _DateLabel(label: 'Mwisho', date: debt.dueDate),
              ],
            ),
            if (debt.note.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                debt.note,
                style: AppTextStyles.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _DebtCardActions(
              debt: debt,
              isBusy: isBusy,
              isReadOnly: isReadOnly,
              onEdit: onEdit,
              onDelete: onDelete,
              onMarkPaid: onMarkPaid,
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtCardActions extends StatelessWidget {
  final BusinessDebt debt;
  final bool isBusy;
  final bool isReadOnly;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarkPaid;

  const _DebtCardActions({
    required this.debt,
    required this.isBusy,
    required this.isReadOnly,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final markPaidButton = OutlinedButton.icon(
      key: Key('mark-paid-${debt.id}'),
      onPressed: isBusy ? null : onMarkPaid,
      icon: isBusy
          ? const KarakanaWaveLoader(size: 16)
          : Icon(
              isReadOnly ? Icons.lock_outline : Icons.check_circle_outline,
              size: 18,
            ),
      label: const Text('Weka Imelipwa', textAlign: TextAlign.center),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.profit,
        side: BorderSide(color: AppColors.profit.withValues(alpha: 0.45)),
        minimumSize: const Size(0, 44),
      ),
    );
    final secondaryActions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: Key('edit-debt-${debt.id}'),
          onPressed: isBusy ? null : onEdit,
          tooltip: 'Hariri deni',
          icon: Icon(
            isReadOnly ? Icons.lock_outline : Icons.edit_outlined,
            color: AppColors.textSecondary,
          ),
        ),
        IconButton(
          key: Key('delete-debt-${debt.id}'),
          onPressed: isBusy ? null : onDelete,
          tooltip: 'Futa deni',
          icon: Icon(
            isReadOnly ? Icons.lock_outline : Icons.delete_outline,
            color: AppColors.error,
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStack = constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.4;
        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (debt.isOutstanding) markPaidButton,
              if (debt.isOutstanding) const SizedBox(height: AppSpacing.xs),
              Align(alignment: Alignment.centerRight, child: secondaryActions),
            ],
          );
        }
        return Row(
          children: [
            if (debt.isOutstanding) Expanded(child: markPaidButton),
            if (debt.isOutstanding) const SizedBox(width: AppSpacing.sm),
            secondaryActions,
          ],
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    );
  }
}

class _DateLabel extends StatelessWidget {
  final String label;
  final DateTime? date;

  const _DateLabel({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: ${_formatDate(date)}',
      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _DebtFormSheet extends StatefulWidget {
  final BusinessDebt? debt;
  final String currency;

  const _DebtFormSheet({this.debt, required this.currency});

  bool get isEditing => debt != null;

  @override
  State<_DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<_DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customerController;
  late final TextEditingController _amountController;
  late final TextEditingController _itemController;
  late final TextEditingController _noteController;
  final _customerFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  final _itemFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();
  late DateTime _dateGiven;
  DateTime? _dueDate;
  late String _status;
  String? _dueDateError;

  @override
  void initState() {
    super.initState();
    final debt = widget.debt;
    _customerController = TextEditingController(text: debt?.customerName ?? '');
    _amountController = TextEditingController(
      text: debt == null
          ? ''
          : _formatAmountForInput(_editableAmount(debt.amount)),
    );
    _itemController = TextEditingController(text: debt?.itemService ?? '');
    _noteController = TextEditingController(text: debt?.note ?? '');
    _dateGiven = debt?.dateGiven ?? DateTime.now();
    _dueDate = debt?.dueDate;
    _status = debt?.status ?? 'outstanding';
  }

  @override
  void dispose() {
    _customerController.dispose();
    _amountController.dispose();
    _itemController.dispose();
    _noteController.dispose();
    _customerFocusNode.dispose();
    _amountFocusNode.dispose();
    _itemFocusNode.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DebtManagementProvider>();
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.modal),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.isEditing ? 'Hariri Deni' : 'Ongeza Deni',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: AppSpacing.md),
                _DebtTextField(
                  key: const Key('debt-customer-field'),
                  controller: _customerController,
                  focusNode: _customerFocusNode,
                  label: 'Jina la Mteja *',
                  hint: 'Mfano: Asha Juma',
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  autofocus: !widget.isEditing,
                  onFieldSubmitted: (_) => _amountFocusNode.requestFocus(),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Weka jina la mteja.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _DebtTextField(
                  key: const Key('debt-amount-field'),
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  label: 'Kiasi (${widget.currency}) *',
                  hint: 'Mfano: 15000',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [_DebtAmountInputFormatter()],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _itemFocusNode.requestFocus(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Weka kiasi cha deni.';
                    }
                    final amount = double.tryParse(_cleanDebtAmount(value));
                    if (amount == null || amount <= 0) {
                      return 'Kiasi lazima kiwe zaidi ya sifuri.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _DebtTextField(
                  controller: _itemController,
                  focusNode: _itemFocusNode,
                  label: 'Bidhaa / Huduma (si lazima)',
                  hint: 'Mfano: Kusuka nywele',
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  onFieldSubmitted: (_) => _noteFocusNode.requestFocus(),
                ),
                const SizedBox(height: AppSpacing.md),
                _DebtDateField(
                  key: const Key('debt-date-given-field'),
                  label: 'Tarehe Iliyotolewa *',
                  date: _dateGiven,
                  onTap: _pickDateGiven,
                ),
                const SizedBox(height: AppSpacing.md),
                _DebtDateField(
                  key: const Key('debt-due-date-field'),
                  label: 'Tarehe ya Mwisho (si lazima)',
                  date: _dueDate,
                  errorText: _dueDateError,
                  onTap: _pickDueDate,
                  onClear: _dueDate == null
                      ? null
                      : () => setState(() {
                            _dueDate = null;
                            _dueDateError = null;
                          }),
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    key: const Key('debt-status-field'),
                    initialValue: _status,
                    decoration: _debtInputDecoration('Hali', null),
                    dropdownColor: AppColors.surface,
                    items: const [
                      DropdownMenuItem(
                        value: 'outstanding',
                        child: Text('Haijalipwa'),
                      ),
                      DropdownMenuItem(value: 'paid', child: Text('Imelipwa')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _DebtTextField(
                  controller: _noteController,
                  focusNode: _noteFocusNode,
                  label: 'Maelezo (si lazima)',
                  hint: 'Maelezo mafupi kuhusu deni',
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  liveRegion: provider.isSubmitting,
                  label: provider.isSubmitting
                      ? 'Inahifadhi, tafadhali subiri'
                      : null,
                  child: FilledButton(
                    key: const Key('save-debt-button'),
                    onPressed: provider.isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.62),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (provider.isSubmitting) ...[
                          const KarakanaWaveLoader(
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Flexible(
                          child: Text(
                            provider.isSubmitting
                                ? 'Inahifadhi...'
                                : widget.isEditing
                                    ? 'Hifadhi Mabadiliko'
                                    : 'Hifadhi Deni',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.buttonMedium,
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
      ),
    );
  }

  Future<void> _pickDateGiven() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateGiven,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateGiven = picked;
        _dueDateError = null;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _dateGiven,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _dueDateError = null;
      });
    }
  }

  Future<void> _submit() async {
    final provider = context.read<DebtManagementProvider>();
    if (provider.isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      if (_customerController.text.trim().isEmpty) {
        _customerFocusNode.requestFocus();
      } else {
        _amountFocusNode.requestFocus();
      }
      return;
    }
    if (_dueDate != null && _dueDate!.isBefore(_dateGiven)) {
      setState(() {
        _dueDateError =
            'Tarehe ya mwisho lazima iwe sawa au baada ya tarehe iliyotolewa.';
      });
      return;
    }
    final debt = widget.debt;
    final ok = debt == null
        ? await provider.createDebt(
            customerName: _customerController.text.trim(),
            amount: _cleanDebtAmount(_amountController.text),
            itemService: _itemController.text.trim(),
            note: _noteController.text.trim(),
            dateGiven: _dateGiven,
            dueDate: _dueDate,
            status: _status,
          )
        : await provider.updateDebt(
            id: debt.id,
            customerName: _customerController.text.trim(),
            amount: _cleanDebtAmount(_amountController.text),
            itemService: _itemController.text.trim(),
            note: _noteController.text.trim(),
            dateGiven: _dateGiven,
            dueDate: _dueDate,
            clearDueDate: debt.dueDate != null && _dueDate == null,
            status: _status,
          );
    if (!mounted) return;
    if (ok) {
      showTopPopup(
        context,
        debt == null ? 'Deni limeongezwa.' : 'Deni limehaririwa.',
        type: TopPopupType.success,
      );
      Navigator.pop(context);
    } else {
      showTopPopup(
        context,
        provider.errorMessage ?? 'Imeshindikana kuhifadhi deni.',
        type: TopPopupType.error,
      );
      provider.clearError();
    }
  }
}

class _DebtTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final int maxLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool autofocus;

  const _DebtTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.validator,
    this.maxLines = 1,
    this.focusNode,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      autofocus: autofocus,
      validator: validator,
      maxLines: maxLines,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: _debtInputDecoration(label, hint),
    );
  }
}

class _DebtDateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String? errorText;

  const _DebtDateField({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: InputDecorator(
        decoration: _debtInputDecoration(label, null).copyWith(
          errorText: errorText,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                color: AppColors.primary, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                date == null ? 'Chagua tarehe' : _formatDate(date),
                style: AppTextStyles.bodyMedium.copyWith(
                  color:
                      date == null ? AppColors.textHint : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                tooltip: 'Ondoa tarehe',
                icon: const Icon(Icons.close, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class _DebtEmptyState extends StatelessWidget {
  final bool filtered;
  final VoidCallback onAdd;
  final VoidCallback onClearFilter;

  const _DebtEmptyState({
    required this.filtered,
    required this.onAdd,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.sectionPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 54, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              filtered ? 'Hakuna madeni katika hali hii' : 'Hakuna madeni bado',
              textAlign: TextAlign.center,
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              filtered
                  ? 'Chagua hali nyingine kuona madeni mengine.'
                  : 'Ongeza deni la kwanza ili uanze kufuatilia malipo ya wateja.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            if (filtered) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onClearFilter,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Onyesha Madeni Yote'),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Ongeza Deni'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DebtLoadingState extends StatelessWidget {
  const _DebtLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const KarakanaWaveLoader(
            size: 34,
            semanticsLabel: 'Inapakia madeni',
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Inapakia madeni...', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _DebtErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DebtErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.sectionPadding,
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Imeshindikana kupakia madeni',
                textAlign: TextAlign.center,
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Jaribu tena'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  final DebtManagementProvider provider;

  const _PaginationFooter({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: KarakanaWaveLoader(
            size: 22,
            semanticsLabel: 'Inapakia madeni zaidi',
          ),
        ),
      );
    }
    if (provider.loadMoreError != null) {
      return TextButton.icon(
        onPressed: provider.loadMore,
        icon: const Icon(Icons.refresh),
        label: const Text('Imeshindikana kupakia zaidi. Jaribu tena.'),
      );
    }
    return const SizedBox.shrink();
  }
}

class _DebtAmountInputFormatter extends TextInputFormatter {
  const _DebtAmountInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = _cleanDebtAmount(newValue.text);
    if (raw.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(raw)) return oldValue;

    final safeCursor = newValue.selection.extentOffset.clamp(
      0,
      newValue.text.length,
    );
    final meaningfulBeforeCursor =
        newValue.text.substring(0, safeCursor).replaceAll(',', '').length;
    final formatted = _formatAmountForInput(raw);
    final cursorOffset = _offsetForMeaningfulCharacters(
      formatted,
      meaningfulBeforeCursor,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  static int _offsetForMeaningfulCharacters(String value, int count) {
    if (count <= 0) return 0;
    var seen = 0;
    for (var index = 0; index < value.length; index++) {
      if (value[index] != ',') seen++;
      if (seen == count) return index + 1;
    }
    return value.length;
  }
}

InputDecoration _debtInputDecoration(String label, String? hint) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    labelStyle: AppTextStyles.labelMedium.copyWith(
      color: AppColors.textSecondary,
    ),
    hintStyle: AppTextStyles.bodySmall,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: AppColors.inputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: AppColors.error, width: 1.5),
    ),
  );
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _money(double value, String currency) {
  final whole = value.round().toString();
  final formatted = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$currency $formatted';
}

String _editableAmount(String amount) {
  final parsed = double.tryParse(amount);
  if (parsed == null) return amount;
  return parsed == parsed.roundToDouble()
      ? parsed.toInt().toString()
      : parsed.toStringAsFixed(2);
}

String _cleanDebtAmount(String value) => value.replaceAll(',', '').trim();

String _formatAmountForInput(String amount) {
  if (amount.isEmpty) return amount;
  final parts = amount.split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return parts.length == 1 ? whole : '$whole.${parts[1]}';
}
