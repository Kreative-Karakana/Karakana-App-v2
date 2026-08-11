import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karakana_app/core/theme/app_colors.dart';
import 'package:karakana_app/core/theme/app_theme.dart';
import 'package:karakana_app/features/subscriptions/models/entitlement_status.dart';
import 'package:karakana_app/features/subscriptions/models/subscription_plan.dart';
import 'package:karakana_app/features/subscriptions/screens/subscription_screen.dart';

import 'support/fake_subscription_api.dart';

void main() {
  setUp(() => AppColors.setBrightness(Brightness.light));
  tearDown(() => AppColors.setBrightness(Brightness.light));

  testWidgets('phone plans use a compact two-column grid', (tester) async {
    await _pumpSubscription(tester, size: const Size(390, 844));

    final trial = find.byKey(const Key('subscription-choice-trial'));
    final daily = find.byKey(
      const Key('subscription-choice-usimamizi-wa-biashara-daily'),
    );
    final weekly = find.byKey(
      const Key('subscription-choice-usimamizi-wa-biashara-weekly'),
    );

    expect(trial, findsOneWidget);
    expect(daily, findsNothing);
    expect(weekly, findsOneWidget);
    expect(tester.getTopLeft(trial).dy, tester.getTopLeft(weekly).dy);
    expect(
      tester.getTopLeft(weekly).dx,
      greaterThan(tester.getTopLeft(trial).dx),
    );
    expect(tester.getSize(trial), tester.getSize(weekly));
    expect(
      tester.getSize(trial).height,
      lessThan(420),
    );
    expect(find.text('Jaribio (Siku 3)'), findsOneWidget);
    expect(find.text('Siku 1'), findsNothing);
    expect(find.text('Wiki 1'), findsOneWidget);
    expect(find.text('Mwezi 1'), findsOneWidget);
    expect(find.text('Anza Jaribio'), findsOneWidget);
    expect(find.text('Endelea na Malipo'), findsNWidgets(2));
    expect(find.text('Jaribio la Siku 3'), findsNothing);
    expect(
      find.descendant(
        of: trial,
        matching: find.byIcon(Icons.rocket_launch_outlined),
      ),
      findsNothing,
    );
    final trialTitle = find.text('Jaribio (Siku 3)');
    final trialPrice = find.text('BURE');
    final trialAction = find.text('Anza Jaribio');
    expect(tester.getTopLeft(trialPrice).dy,
        greaterThan(tester.getTopLeft(trialTitle).dy));
    expect(tester.getTopLeft(trialAction).dy,
        greaterThan(tester.getTopLeft(trialPrice).dy));

    final weeklyTitle = find.text('Wiki 1');
    final weeklyPrice = find.text('7,900 TZS');
    final firstPaidAction = find.text('Endelea na Malipo').first;
    expect(tester.getTopLeft(weeklyPrice).dy,
        greaterThan(tester.getTopLeft(weeklyTitle).dy));
    expect(tester.getTopLeft(firstPaidAction).dy,
        greaterThan(tester.getTopLeft(weeklyPrice).dy));
    expect(
      find.descendant(
        of: weekly,
        matching: find.byIcon(Icons.workspace_premium_outlined),
      ),
      findsNothing,
    );
    expect(
      find.text('Ununuzi haupatikani kwenye kifaa hiki'),
      findsNothing,
    );
    expect(find.text('Chagua Mpango Wako'), findsOneWidget);
    expect(find.text('29,900 TZS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small width and large text use a readable single column',
      (tester) async {
    await _pumpSubscription(
      tester,
      size: const Size(320, 700),
      textScale: 1.5,
    );

    final trial = find.byKey(const Key('subscription-choice-trial'));
    final weekly = find.byKey(
      const Key('subscription-choice-usimamizi-wa-biashara-weekly'),
    );

    expect(
        tester.getTopLeft(weekly).dy, greaterThan(tester.getTopLeft(trial).dy));
    expect(tester.getSize(trial).width, tester.getSize(weekly).width);
    expect(tester.takeException(), isNull);
  });

  testWidgets('medium tablet widths use two content-sized columns',
      (tester) async {
    await _pumpSubscription(
      tester,
      size: const Size(768, 900),
    );

    final trial = find.byKey(const Key('subscription-choice-trial'));
    final weekly = find.byKey(
      const Key('subscription-choice-usimamizi-wa-biashara-weekly'),
    );

    expect(tester.getTopLeft(trial).dy, tester.getTopLeft(weekly).dy);
    expect(
        tester.getTopLeft(weekly).dx, greaterThan(tester.getTopLeft(trial).dx));
    expect(tester.getSize(trial).height, lessThan(400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('large tablet widths align trial and plans in three columns',
      (tester) async {
    await _pumpSubscription(
      tester,
      size: const Size(1024, 900),
      brightness: Brightness.dark,
    );

    final cards = [
      find.byKey(const Key('subscription-choice-trial')),
      find.byKey(
        const Key('subscription-choice-usimamizi-wa-biashara-weekly'),
      ),
      find.byKey(
        const Key('subscription-choice-usimamizi-wa-biashara-monthly'),
      ),
    ];
    final firstRowY = tester.getTopLeft(cards.first).dy;

    for (final card in cards.skip(1)) {
      expect(tester.getTopLeft(card).dy, firstRowY);
    }
    expect(tester.getSize(cards.first).height, lessThan(400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('active trial card shows an activated state', (tester) async {
    await _pumpSubscription(
      tester,
      size: const Size(390, 844),
      entitlementStatus: 'trial',
      trialEligible: false,
    );

    expect(find.text('Imeamilishwa'), findsOneWidget);
    final trialButton = tester.widget<FilledButton>(
      find.byKey(const Key('start-subscription-trial')),
    );
    expect(trialButton.onPressed, isNull);
    final countdown = find.textContaining('Jaribio lako limebaki siku');
    expect(countdown, findsOneWidget);
    expect(tester.getSize(countdown).height, lessThan(30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('expired paid access can still start a first trial',
      (tester) async {
    await _pumpSubscription(
      tester,
      size: const Size(390, 844),
      entitlementStatus: 'expired',
      trialEligible: true,
    );

    final trialButton = tester.widget<FilledButton>(
      find.byKey(const Key('start-subscription-trial')),
    );
    expect(trialButton.onPressed, isNotNull);
  });

  testWidgets('backend-ineligible account cannot restart a trial',
      (tester) async {
    await _pumpSubscription(
      tester,
      size: const Size(390, 844),
      trialEligible: false,
    );

    final trialButton = tester.widget<FilledButton>(
      find.byKey(const Key('start-subscription-trial')),
    );
    expect(trialButton.onPressed, isNull);
  });
}

Future<void> _pumpSubscription(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  String entitlementStatus = 'none',
  bool trialEligible = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  AppColors.setBrightness(brightness);
  final plans = [
    const SubscriptionPlan(
      id: 1,
      name: 'Jaribio la Siku 3',
      slug: 'usimamizi-wa-biashara-trial',
      billingPeriod: 'custom',
      durationDays: 3,
      price: '0.00',
      currency: 'TZS',
      features: [],
    ),
    const SubscriptionPlan(
      id: 2,
      name: 'Usimamizi wa Biashara Daily',
      slug: 'usimamizi-wa-biashara-daily',
      billingPeriod: 'daily',
      durationDays: 1,
      price: '1000.00',
      currency: 'TZS',
      features: [],
    ),
    const SubscriptionPlan(
      id: 3,
      name: 'Usimamizi wa Biashara Weekly',
      slug: 'usimamizi-wa-biashara-weekly',
      billingPeriod: 'weekly',
      durationDays: 7,
      price: '7900.00',
      currency: 'TZS',
      features: [],
    ),
    const SubscriptionPlan(
      id: 4,
      name: 'Usimamizi wa Biashara Monthly',
      slug: 'usimamizi-wa-biashara-monthly',
      billingPeriod: 'monthly',
      durationDays: 30,
      price: '29900.00',
      currency: 'TZS',
      features: [],
    ),
  ];
  final api = FakeSubscriptionApi(
    status: EntitlementStatus(
      hasActiveSubscription: entitlementStatus == 'trial',
      trialEligible: trialEligible,
      status: entitlementStatus,
      expiryDate: entitlementStatus == 'trial'
          ? DateTime.now().add(const Duration(days: 2))
          : null,
    ),
    plans: plans,
  );
  final router = GoRouter(
    initialLocation: '/subscription',
    routes: [
      GoRoute(
        path: '/subscription',
        builder: (_, __) => SubscriptionScreen(service: api),
      ),
      GoRoute(
        path: '/zana/biz-manager',
        builder: (_, __) => const Scaffold(body: Text('Business')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode:
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
