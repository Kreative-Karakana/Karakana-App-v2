import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karakana_app/core/theme/app_colors.dart';
import 'package:karakana_app/core/theme/app_theme.dart';
import 'package:karakana_app/features/zana/models/zana_model.dart';
import 'package:karakana_app/features/zana/screens/zana_screen.dart';

void main() {
  setUp(() => AppColors.setBrightness(Brightness.light));
  tearDown(() => AppColors.setBrightness(Brightness.light));

  test('tool order and destinations preserve the approved hierarchy', () {
    expect(
      ZanaData.tools.map((tool) => tool.id),
      ['biz-manager', 'kikoba', 'ebooks', 'insurance'],
    );
    expect(ZanaData.tools.first.isRecommended, isTrue);
    expect(
      ZanaData.tools.map((tool) => tool.route),
      [
        '/zana/biz-manager',
        '/zana/kikoba',
        '/zana/ebooks',
        '/zana/insurance',
      ],
    );
  });

  testWidgets('small phones render a consistent two-column tool grid',
      (tester) async {
    await _pumpZana(tester, size: const Size(375, 812));

    final first = find.byKey(const Key('zana-card-biz-manager'));
    final second = find.byKey(const Key('zana-card-kikoba'));
    final third = find.byKey(const Key('zana-card-ebooks'));

    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    expect(third, findsOneWidget);
    expect(tester.getTopLeft(first).dy, tester.getTopLeft(second).dy);
    expect(tester.getTopLeft(first).dx, lessThan(tester.getTopLeft(second).dx));
    expect(
        tester.getTopLeft(third).dy, greaterThan(tester.getTopLeft(first).dy));
    expect(tester.getSize(first).height, tester.getSize(second).height);
    expect(tester.getSize(first).width, greaterThan(160));
    expect(tester.getSize(first).height, 228);

    final primaryTitle = tester.renderObject<RenderParagraph>(
      find.text('Usimamizi wa Biashara'),
    );
    expect(primaryTitle.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact hero and arrow treatment preserve visual balance',
      (tester) async {
    await _pumpZana(tester, size: const Size(375, 812));

    final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
    final arrow = find.byKey(const Key('zana-arrow-kikoba'));
    final primaryMaterial = tester.widget<Material>(
      find.byKey(const Key('zana-material-biz-manager')),
    );

    expect(appBar.expandedHeight, 164);
    expect(tester.getSize(arrow), const Size.square(32));
    expect(primaryMaterial.elevation, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('medium widths adapt to three columns', (tester) async {
    await _pumpZana(tester, size: const Size(768, 900));

    final cards = [
      find.byKey(const Key('zana-card-biz-manager')),
      find.byKey(const Key('zana-card-kikoba')),
      find.byKey(const Key('zana-card-ebooks')),
      find.byKey(const Key('zana-card-insurance')),
    ];

    expect(tester.getTopLeft(cards[0]).dy, tester.getTopLeft(cards[1]).dy);
    expect(tester.getTopLeft(cards[1]).dy, tester.getTopLeft(cards[2]).dy);
    expect(tester.getTopLeft(cards[3]).dy,
        greaterThan(tester.getTopLeft(cards[0]).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide and landscape layouts adapt to four columns',
      (tester) async {
    await _pumpZana(tester, size: const Size(1024, 600));

    final cards = [
      find.byKey(const Key('zana-card-biz-manager')),
      find.byKey(const Key('zana-card-kikoba')),
      find.byKey(const Key('zana-card-ebooks')),
      find.byKey(const Key('zana-card-insurance')),
    ];
    final firstRowY = tester.getTopLeft(cards.first).dy;

    for (final card in cards.skip(1)) {
      expect(tester.getTopLeft(card).dy, firstRowY);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('e-Kikoba appears once and card navigation remains active',
      (tester) async {
    await _pumpZana(tester, size: const Size(390, 844));

    expect(find.text('Akiba ya Kikundi'), findsOneWidget);
    await tester.tap(find.byKey(const Key('zana-card-biz-manager')));
    await tester.pumpAndSettle();

    expect(find.text('destination: /zana/biz-manager'), findsOneWidget);
  });

  testWidgets('cards omit status labels and repeated section introduction',
      (tester) async {
    await _pumpZana(tester, size: const Size(390, 844));

    expect(find.text('Fursa'), findsNothing);
    expect(find.text('Tayari'), findsNothing);
    expect(find.text('Karibu'), findsNothing);
    expect(find.text('Zana za biashara'), findsNothing);
    expect(
      find.text(
        'Chagua zana inayokusaidia kusimamia, kujifunza na kukuza biashara.',
      ),
      findsNothing,
    );
  });

  testWidgets('business management description is fully visible',
      (tester) async {
    await _pumpZana(tester, size: const Size(320, 700));

    final description = find.text(
      'Simamia operesheni na mauzo ya biashara yako kwa urahisi.',
    );
    final paragraph = tester.renderObject<RenderParagraph>(description);

    expect(description, findsOneWidget);
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large accessibility text remains overflow-free on a small phone',
      (tester) async {
    await _pumpZana(
      tester,
      size: const Size(320, 700),
      textScale: 1.5,
    );

    expect(find.byKey(const Key('zana-card-biz-manager')), findsOneWidget);
    expect(find.byKey(const Key('zana-card-kikoba')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const Key('zana-scroll-view')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark mode uses the same responsive structure', (tester) async {
    await _pumpZana(
      tester,
      size: const Size(430, 900),
      brightness: Brightness.dark,
    );

    expect(find.byKey(const Key('zana-card-biz-manager')), findsOneWidget);
    expect(find.text('Zana'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpZana(
  WidgetTester tester, {
  required Size size,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  AppColors.setBrightness(brightness);
  final router = GoRouter(
    initialLocation: '/zana',
    routes: [
      GoRoute(
        path: '/zana',
        builder: (_, __) => const ZanaScreen(),
      ),
      for (final tool in ZanaData.tools)
        GoRoute(
          path: tool.route,
          builder: (_, __) => Scaffold(
            body: Text('destination: ${tool.route}'),
          ),
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
