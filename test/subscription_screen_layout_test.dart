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

  testWidgets('trial and paid plan align in two columns on phones',
      (tester) async {
    await _pumpSubscription(tester, size: const Size(390, 844));

    final trial = find.byKey(const Key('subscription-choice-trial'));
    final monthly = find.byKey(const Key('subscription-choice-monthly'));

    expect(trial, findsOneWidget);
    expect(monthly, findsOneWidget);
    expect(tester.getTopLeft(trial).dy, tester.getTopLeft(monthly).dy);
    expect(
        tester.getTopLeft(trial).dx, lessThan(tester.getTopLeft(monthly).dx));
    expect(
      tester.getSize(find.byKey(const Key('subscription-choice-slot-0'))),
      tester.getSize(find.byKey(const Key('subscription-choice-slot-1'))),
    );
    expect(find.text('Chagua Mpango Wako'), findsOneWidget);
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
    final monthly = find.byKey(const Key('subscription-choice-monthly'));

    expect(tester.getTopLeft(monthly).dy,
        greaterThan(tester.getTopLeft(trial).dy));
    expect(tester.getSize(trial).width, tester.getSize(monthly).width);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet widths align trial and plans in three columns',
      (tester) async {
    await _pumpSubscription(
      tester,
      size: const Size(1024, 900),
      includeAnnualPlan: true,
      brightness: Brightness.dark,
    );

    final cards = [
      find.byKey(const Key('subscription-choice-trial')),
      find.byKey(const Key('subscription-choice-monthly')),
      find.byKey(const Key('subscription-choice-annual')),
    ];
    final firstRowY = tester.getTopLeft(cards.first).dy;

    for (final card in cards.skip(1)) {
      expect(tester.getTopLeft(card).dy, firstRowY);
    }
    expect(
      tester
          .getSize(find.byKey(const Key('subscription-choice-slot-0')))
          .height,
      400,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSubscription(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  bool includeAnnualPlan = false,
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
      name: 'Mpango wa Mwezi',
      slug: 'monthly',
      billingPeriod: 'monthly',
      durationDays: 30,
      price: '5000.00',
      currency: 'TZS',
      features: [
        SubscriptionFeature(
          code: 'business',
          name: 'Usimamizi wa Biashara',
          description: '',
        ),
      ],
    ),
    if (includeAnnualPlan)
      const SubscriptionPlan(
        id: 2,
        name: 'Mpango wa Mwaka',
        slug: 'annual',
        billingPeriod: 'yearly',
        durationDays: 365,
        price: '50000.00',
        currency: 'TZS',
        features: [
          SubscriptionFeature(
            code: 'business',
            name: 'Usimamizi wa Biashara',
            description: '',
          ),
        ],
      ),
  ];
  final api = FakeSubscriptionApi(
    status: const EntitlementStatus(
      hasActiveSubscription: false,
      status: 'none',
      expiryDate: null,
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
