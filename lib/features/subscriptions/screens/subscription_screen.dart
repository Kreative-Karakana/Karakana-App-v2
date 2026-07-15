import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/common/karakana_wave_loader.dart';
import '../../../widgets/common/top_popup.dart';
import '../../payments/utils/mobile_money.dart';
import '../../payments/services/iap_service.dart';
import '../config/subscription_checkout_config.dart';
import '../models/entitlement_status.dart';
import '../models/subscription_plan.dart';
import '../providers/subscription_checkout_provider.dart';
import '../providers/subscription_purchase_provider.dart';
import '../providers/subscription_status_provider.dart';

/// Subscription status + upgrade screen (issue #33) — the single place in
/// Flutter that shows a user what their entitlement actually is. Purely a
/// display/purchase-entry layer on top of `subscriptions/me/`,
/// `subscriptions/plans/`, `subscriptions/trial/activate/`, and
/// [IAPService]; it never itself decides whether a feature is unlocked
/// (see docs/apps/subscriptions.md, Security).
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SubscriptionStatusProvider()..load(),
        ),
        ChangeNotifierProvider(create: (_) => SubscriptionCheckoutProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionPurchaseProvider()),
      ],
      child: const _SubscriptionView(),
    );
  }
}

class _SubscriptionView extends StatefulWidget {
  const _SubscriptionView();

  @override
  State<_SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<_SubscriptionView>
    with WidgetsBindingObserver {
  final SubscriptionCheckoutConfig _checkoutConfig =
      SubscriptionCheckoutConfig.forPlatform();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final checkout = context.read<SubscriptionCheckoutProvider>();
    checkout.handleAppResumed(
      refreshEntitlement: context.read<SubscriptionStatusProvider>().load,
    );
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
          'Usajili Wangu',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Consumer<SubscriptionStatusProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.entitlement == null) {
            return const _LoadingState();
          }

          final entitlement = provider.entitlement;
          if (entitlement == null) {
            return _ErrorState(
              message: provider.errorMessage ??
                  'Hatukuweza kupata taarifa za usajili wako kwa sasa.',
              onRetry: provider.load,
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: provider.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              children: [
                _StatusCard(entitlement: entitlement),
                const SizedBox(height: 18),
                if (entitlement.isNone)
                  _TrialOfferCard(
                    isActivating: provider.isActivatingTrial,
                    onStart: () => _activateTrial(context),
                  ),
                if (entitlement.isNone) const SizedBox(height: 18),
                if (!entitlement.isActive || entitlement.isTrial)
                  _PlansSection(
                      plans: provider.plans,
                      isLoading: provider.isLoadingPlans,
                      errorMessage: provider.plansErrorMessage,
                      checkoutConfig: _checkoutConfig,
                      onRetry: provider.loadPlans),
                const SizedBox(height: 18),
                const _RestorePurchasesButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _activateTrial(BuildContext context) async {
    final provider = context.read<SubscriptionStatusProvider>();
    final started = await provider.activateTrial();
    if (!context.mounted) return;
    if (started) {
      showTopPopup(
        context,
        'Jaribio lako la siku 3 limeanza! Karibu ujaribu Usimamizi wa Biashara.',
        isError: false,
      );
    } else if (provider.trialErrorMessage != null) {
      showTopPopup(context, provider.trialErrorMessage!);
      provider.clearTrialError();
    }
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KarakanaWaveLoader(color: AppColors.primary),
          const SizedBox(height: 14),
          const _MutedText('Inapakia taarifa za usajili...'),
        ],
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  final String text;
  const _MutedText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 13,
        color: AppColors.textTertiary,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                color: AppColors.textTertiary, size: 44),
            const SizedBox(height: 14),
            Text(
              'Imeshindikana kupakia',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => onRetry(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: Text(
                'Jaribu Tena',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders exactly one of the four states the backend can report — trial,
/// paid-active, read-only-on-lapse (expired/cancelled/suspended), or
/// never-subscribed — from the single [EntitlementStatus] the screen
/// fetched. See docs/apps/subscriptions.md, Flutter considerations: "Three
/// states to render, not two" (trial/active count as one branch here since
/// their card layout only differs in a few lines of copy).
class _StatusCard extends StatelessWidget {
  final EntitlementStatus entitlement;

  const _StatusCard({required this.entitlement});

  @override
  Widget build(BuildContext context) {
    if (entitlement.hasActiveSubscription) {
      return entitlement.isTrial
          ? _TrialActiveCard(entitlement: entitlement)
          : _SubscriptionActiveCard(entitlement: entitlement);
    }
    if (entitlement.isNone) {
      return const _NoAccessCard();
    }
    return _ExpiredCard(entitlement: entitlement);
  }
}

class _CardShell extends StatelessWidget {
  final List<Color> gradient;
  final Widget child;

  const _CardShell({required this.gradient, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.modal),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatusBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrialActiveCard extends StatelessWidget {
  final EntitlementStatus entitlement;
  const _TrialActiveCard({required this.entitlement});

  @override
  Widget build(BuildContext context) {
    final days = entitlement.remainingDays ?? 0;
    final countdown = days <= 0
        ? 'Jaribio lako linaisha leo'
        : 'Jaribio lako limebaki siku $days';
    return _CardShell(
      gradient: AppColors.headerGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StatusBadge(
              label: 'JARIBIO LINAENDELEA', icon: Icons.timelapse_rounded),
          const SizedBox(height: 16),
          Text(
            countdown,
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Baada ya jaribio kuisha, utahitaji kuboresha akaunti yako ili '
            'kuendelea kutumia Usimamizi wa Biashara.',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          if (entitlement.expiryDate != null) ...[
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.event_busy_outlined,
              label: 'Jaribio linaisha',
              value: _formatDate(entitlement.expiryDate!),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubscriptionActiveCard extends StatelessWidget {
  final EntitlementStatus entitlement;
  const _SubscriptionActiveCard({required this.entitlement});

  @override
  Widget build(BuildContext context) {
    final plan = entitlement.plan;
    return _CardShell(
      gradient: const [Color(0xFF1B5E20), Color(0xFF2E7D32)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StatusBadge(
              label: 'USAJILI AMILIFU', icon: Icons.verified_rounded),
          const SizedBox(height: 16),
          Text(
            plan?.name.isNotEmpty == true ? plan!.name : 'Mpango wa Kulipia',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Una ufikiaji kamili wa huduma za premium.',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),
          if (plan != null)
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Bei',
              value:
                  '${_formatMoney(plan.price)} ${plan.currency} ${_billingPeriodLabel(plan)}',
            ),
          if (entitlement.expiryDate != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.event_available_outlined,
              label: 'Itaisha tarehe',
              value: _formatDate(entitlement.expiryDate!),
            ),
          ],
          if (plan != null && plan.features.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f.name.isNotEmpty ? f.name : f.code,
                        style: GoogleFonts.montserrat(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpiredCard extends StatelessWidget {
  final EntitlementStatus entitlement;
  const _ExpiredCard({required this.entitlement});

  @override
  Widget build(BuildContext context) {
    final heading = entitlement.isCancelled
        ? 'Usajili wako umesitishwa'
        : entitlement.isSuspended
            ? 'Usajili wako umesimamishwa'
            : 'Muda wa usajili/jaribio wako umeisha';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.modal),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_clock_outlined,
                  color: AppColors.warning, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  heading,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Taarifa zako zipo salama. Boresha akaunti yako ili kuendelea '
            'kuongeza na kuhariri taarifa za biashara yako — bado unaweza '
            'kuona taarifa zako zilizopo.',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
          if (entitlement.expiryDate != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.event_busy_outlined,
              label: 'Ilikuwa hai hadi',
              value: _formatDate(entitlement.expiryDate!),
              dark: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _NoAccessCard extends StatelessWidget {
  const _NoAccessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.modal),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.workspace_premium_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Huna ufikiaji wa huduma za premium bado',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Anza jaribio la siku 3 bila malipo ili kujaribu Usimamizi wa '
            'Biashara, au nunua usajili moja kwa moja hapa chini.',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool dark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = dark ? AppColors.textPrimary : Colors.white;
    final labelColor =
        dark ? AppColors.textTertiary : Colors.white.withValues(alpha: 0.75);
    return Row(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.85), size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.montserrat(fontSize: 12.5, color: labelColor),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TrialOfferCard extends StatelessWidget {
  final bool isActivating;
  final VoidCallback onStart;

  const _TrialOfferCard({required this.isActivating, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isActivating ? null : onStart,
        icon: isActivating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.rocket_launch_outlined, size: 18),
        label: Text(
          isActivating ? 'Inaanzisha...' : 'Anza Jaribio la Siku 3',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
    );
  }
}

class _PlansSection extends StatelessWidget {
  final List<SubscriptionPlan> plans;
  final bool isLoading;
  final String? errorMessage;
  final SubscriptionCheckoutConfig checkoutConfig;
  final Future<void> Function() onRetry;

  const _PlansSection({
    required this.plans,
    required this.isLoading,
    required this.errorMessage,
    required this.checkoutConfig,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mipango ya Usajili',
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: KarakanaWaveLoader(color: AppColors.primary, size: 28),
            ),
          )
        else if (errorMessage != null)
          _PlansErrorRow(message: errorMessage!, onRetry: onRetry)
        else if (plans.isEmpty)
          const _MutedText('Hakuna mipango ya usajili inayopatikana kwa sasa.')
        else
          ...plans.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlanCard(plan: p, checkoutConfig: checkoutConfig),
              )),
      ],
    );
  }
}

class _PlansErrorRow extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _PlansErrorRow({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.montserrat(
                  fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => onRetry(),
            child: Text(
              'Jaribu Tena',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final SubscriptionCheckoutConfig checkoutConfig;
  const _PlanCard({required this.plan, required this.checkoutConfig});

  @override
  Widget build(BuildContext context) {
    final availability = _purchaseAvailability(plan, checkoutConfig);
    final productId = availability.storeProductId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${_formatMoney(plan.price)} ${plan.currency}',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _billingPeriodLabel(plan),
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: AppColors.primary, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f.name.isNotEmpty ? f.name : f.code,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (availability.canUseExternalCheckout) ...[
            _ExternalCheckoutButton(plan: plan),
            if (availability.canUseStorePurchase &&
                productId != null &&
                productId.isNotEmpty) ...[
              const SizedBox(height: 8),
              _StorePurchaseButton(
                productId: productId,
                label: 'Nunua kupitia Duka',
                onPurchase: _purchase,
              ),
            ],
          ] else if (availability.canUseStorePurchase &&
              productId != null &&
              productId.isNotEmpty)
            _StorePurchaseButton(
              productId: productId,
              label: 'Nunua Sasa',
              onPurchase: _purchase,
            )
          else
            _UnavailablePurchaseButton(
              message: availability.canUseStorePurchase
                  ? 'Ununuzi wa App Store haujasanidiwa bado'
                  : 'Ununuzi haupatikani kwenye kifaa hiki',
            ),
        ],
      ),
    );
  }

  Future<void> _purchase(BuildContext context, String productId) async {
    final purchase = context.read<SubscriptionPurchaseProvider>();
    final ready = await purchase.initialize(productId);
    if (!context.mounted) return;
    if (!ready) {
      if (purchase.errorMessage != null) {
        showTopPopup(context, purchase.errorMessage!);
      }
      return;
    }

    await purchase.purchase(productId);
    if (!context.mounted) return;

    if (purchase.purchaseSuccess) {
      showTopPopup(context, 'Usajili wako umefanikiwa!', isError: false);
      await context.read<SubscriptionStatusProvider>().load();
    } else if (purchase.errorMessage != null) {
      showTopPopup(context, purchase.errorMessage!);
    }
  }
}

SubscriptionPurchaseAvailability _purchaseAvailability(
  SubscriptionPlan plan,
  SubscriptionCheckoutConfig config,
) {
  final productId = config.enableAppleIap
      ? plan.appleIapProductId
      : config.enableGooglePlayBilling
          ? plan.googlePlayProductId
          : null;
  return SubscriptionPurchaseAvailability(
    canUseExternalCheckout: config.enableExternalSubscriptionCheckout,
    canUseStorePurchase:
        config.enableAppleIap || config.enableGooglePlayBilling,
    storeProductId: productId,
  );
}

class _ExternalCheckoutButton extends StatelessWidget {
  final SubscriptionPlan plan;

  const _ExternalCheckoutButton({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionCheckoutProvider>(
      builder: (context, checkout, _) {
        final isCurrentPending = checkout.pendingPlanSlug == plan.slug &&
            checkout.isWaitingForPayment;
        final label = isCurrentPending
            ? 'Nimekamilisha malipo / Angalia hali'
            : 'Lipa kwa Mobile Money';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: checkout.isBusy && !isCurrentPending
                  ? null
                  : () => isCurrentPending
                      ? _checkStatus(context)
                      : _showMobileMoneySheet(context, plan),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              icon: checkout.state == SubscriptionCheckoutState.creatingCheckout
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.phone_android_rounded, size: 18),
              label: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            if (isCurrentPending) ...[
              const SizedBox(height: 8),
              Text(
                'Malipo yakithibitishwa, tutasasisha usajili kutoka kwenye seva.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 11.5,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _checkStatus(BuildContext context) async {
    final checkout = context.read<SubscriptionCheckoutProvider>();
    await checkout.checkPendingPayment(
      refreshEntitlement: context.read<SubscriptionStatusProvider>().load,
    );
    if (!context.mounted) return;
    _showCheckoutState(context, checkout);
  }

  Future<void> _showMobileMoneySheet(
      BuildContext context, SubscriptionPlan plan) async {
    final result = await showModalBottomSheet<_MobileMoneySelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.modal),
      ),
      builder: (_) => _MobileMoneyCheckoutSheet(plan: plan),
    );
    if (result == null || !context.mounted) return;

    final checkout = context.read<SubscriptionCheckoutProvider>();
    await checkout.startCheckout(
      plan: plan,
      rawPhoneNumber: result.phoneNumber,
      provider: result.provider,
      refreshEntitlement: context.read<SubscriptionStatusProvider>().load,
    );
    if (!context.mounted) return;
    _showCheckoutState(context, checkout);
  }
}

void _showCheckoutState(
  BuildContext context,
  SubscriptionCheckoutProvider checkout,
) {
  switch (checkout.state) {
    case SubscriptionCheckoutState.successful:
      showTopPopup(context, 'Usajili wako umefanikiwa!', isError: false);
      checkout.reset();
      break;
    case SubscriptionCheckoutState.failed:
    case SubscriptionCheckoutState.timedOut:
      if (checkout.errorMessage != null) {
        showTopPopup(context, checkout.errorMessage!);
      }
      break;
    case SubscriptionCheckoutState.idle:
    case SubscriptionCheckoutState.creatingCheckout:
    case SubscriptionCheckoutState.waitingForPayment:
      showTopPopup(
        context,
        'Malipo yanasubiri uthibitisho. Angalia hali baada ya kuthibitisha.',
        isError: false,
      );
      break;
  }
}

class _StorePurchaseButton extends StatelessWidget {
  final String productId;
  final String label;
  final Future<void> Function(BuildContext context, String productId)
      onPurchase;

  const _StorePurchaseButton({
    required this.productId,
    required this.label,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionPurchaseProvider>(
      builder: (context, purchase, _) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed:
              purchase.isLoading ? null : () => onPurchase(context, productId),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: purchase.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  label,
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700, color: Colors.white),
                ),
        ),
      ),
    );
  }
}

class _UnavailablePurchaseButton extends StatelessWidget {
  final String message;

  const _UnavailablePurchaseButton({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: Text(
          message,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _MobileMoneySelection {
  final String provider;
  final String phoneNumber;

  const _MobileMoneySelection({
    required this.provider,
    required this.phoneNumber,
  });
}

class _MobileMoneyCheckoutSheet extends StatefulWidget {
  final SubscriptionPlan plan;

  const _MobileMoneyCheckoutSheet({required this.plan});

  @override
  State<_MobileMoneyCheckoutSheet> createState() =>
      _MobileMoneyCheckoutSheetState();
}

class _MobileMoneyCheckoutSheetState extends State<_MobileMoneyCheckoutSheet> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedProvider = MobileMoney.providers.first.id;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.plan.name,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatMoney(widget.plan.price)} ${widget.plan.currency} ${_billingPeriodLabel(widget.plan)}',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chagua Njia ya Malipo',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...MobileMoney.providers.map(_providerTile),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nambari ya Simu',
                hintText: '0712345678',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Mfano: 0712345678 au 712345678. Kiasi hakiwezi kubadilishwa.',
              style: GoogleFonts.montserrat(
                fontSize: 11.5,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    _MobileMoneySelection(
                      provider: _selectedProvider,
                      phoneNumber: _phoneController.text,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: Text(
                  'Endelea Kulipa',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _providerTile(MobileMoneyProviderOption provider) {
    final isSelected = provider.id == _selectedProvider;
    return GestureDetector(
      onTap: () => setState(() => _selectedProvider = provider.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: isSelected ? provider.color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              provider.logoAsset,
              width: 34,
              height: 34,
              errorBuilder: (_, __, ___) => Icon(
                Icons.phone_android_rounded,
                color: provider.color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                provider.name,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? provider.color : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _RestorePurchasesButton extends StatelessWidget {
  const _RestorePurchasesButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionPurchaseProvider>(
      builder: (context, purchase, _) => Center(
        child: TextButton(
          onPressed: purchase.isLoading ? null : () => _restore(context),
          child: Text(
            'Rejesha Ununuzi Uliopita',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _restore(BuildContext context) async {
    final ready = await IAPService.instance.initialize();
    if (!context.mounted) return;
    if (!ready) {
      showTopPopup(context, 'Usajili haupatikani kwenye kifaa hiki.');
      return;
    }

    final purchase = context.read<SubscriptionPurchaseProvider>();
    await purchase.restore();
    if (!context.mounted) return;

    if (purchase.restoreSuccess) {
      showTopPopup(context, 'Ununuzi wako umerejeshwa!', isError: false);
      await context.read<SubscriptionStatusProvider>().load();
    } else if (purchase.errorMessage != null) {
      showTopPopup(context, purchase.errorMessage!);
    }
  }
}

String _formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

String _formatMoney(String price) {
  final value = double.tryParse(price) ?? 0;
  return NumberFormat('#,###', 'en_US').format(value);
}

String _billingPeriodLabel(SubscriptionPlan plan) {
  switch (plan.billingPeriod) {
    case 'daily':
      return 'kwa siku';
    case 'weekly':
      return 'kwa wiki';
    case 'monthly':
      return 'kwa mwezi';
    default:
      return 'kwa siku ${plan.durationDays}';
  }
}
