import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karakana_app/features/ebooks/models/ebook.dart';
import 'package:karakana_app/features/ebooks/providers/ebook_provider.dart';
import 'package:karakana_app/features/ebooks/screens/ebook_detail_screen.dart';
import 'package:karakana_app/features/ebooks/services/ebook_service.dart';
import 'package:karakana_app/features/payments/providers/iap_provider.dart';
import 'package:karakana_app/features/payments/services/iap_service.dart';
import 'package:provider/provider.dart';

class _FakeEbookService extends EbookService {
  _FakeEbookService(this.ebook);

  Ebook ebook;

  @override
  Future<Ebook> fetchDetail(int id) async => ebook;
}

class _FakeEbookProvider extends EbookProvider {
  int libraryRefreshes = 0;
  int storeRefreshes = 0;

  @override
  Future<void> fetchLibrary() async {
    libraryRefreshes += 1;
  }

  @override
  Future<void> fetchStore() async {
    storeRefreshes += 1;
  }
}

class _FakeIAPProvider extends IAPProvider {
  _FakeIAPProvider({required this.succeeds});

  final bool succeeds;
  int ebookInitializations = 0;
  int ebookPurchases = 0;

  @override
  Future<void> initializeForEbook(String productId) async {
    ebookInitializations += 1;
    errorMessage = null;
  }

  @override
  Future<void> purchase(
    String productId, {
    IAPProductKind kind = IAPProductKind.course,
  }) async {
    expect(kind, IAPProductKind.ebook);
    ebookPurchases += 1;
    purchaseSuccess = succeeds;
    errorMessage = succeeds ? null : 'Uthibitisho wa malipo umeshindwa.';
  }

  @override
  String? localizedPrice(String productId) => 'TSh 12,000';
}

Ebook _paidEbook() => const Ebook(
      id: 7,
      title: 'Biashara Imara',
      description: 'Mwongozo wa biashara.',
      authorName: 'Karakana',
      coverImageUrl: null,
      priceInTzs: 12000,
      totalPages: 42,
      isPurchased: false,
      isPaymentExempt: false,
      appleIapProductId: 'com.kreativekarakana.karakana.ebook.biashara',
      status: 'published',
      buyersCount: 0,
      successfulPurchasesCount: 0,
      totalRevenue: 0,
      createdAt: null,
      updatedAt: null,
    );

Widget _testApp({
  required EbookService service,
  required EbookProvider ebookProvider,
  required IAPProvider iapProvider,
}) {
  final router = GoRouter(
    initialLocation: '/zana/ebooks/7',
    routes: [
      GoRoute(
        path: '/zana/ebooks/library',
        builder: (_, __) => const Scaffold(body: Text('Library destination')),
      ),
      GoRoute(
        path: '/zana/ebooks/:id',
        builder: (_, __) => EbookDetailScreen(ebookId: 7, service: service),
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<EbookProvider>.value(value: ebookProvider),
      ChangeNotifierProvider<IAPProvider>.value(value: iapProvider),
    ],
    child: MaterialApp.router(
      theme: ThemeData(platform: TargetPlatform.iOS),
      routerConfig: router,
    ),
  );
}

void main() {
  test('paid iOS eBooks select Apple IAP and Android selects EVPay', () {
    expect(
      ebookPurchaseRail(
        isIOS: true,
        isOwned: false,
        isFree: false,
        isPaymentExempt: false,
        hasAppleProduct: true,
      ),
      EbookPurchaseRail.appleIap,
    );
    expect(
      ebookPurchaseRail(
        isIOS: false,
        isOwned: false,
        isFree: false,
        isPaymentExempt: false,
        hasAppleProduct: true,
      ),
      EbookPurchaseRail.evpay,
    );
  });

  test('free and staff-exempt eBooks bypass payment rails', () {
    for (final isPaymentExempt in [false, true]) {
      expect(
        ebookPurchaseRail(
          isIOS: true,
          isOwned: false,
          isFree: !isPaymentExempt,
          isPaymentExempt: isPaymentExempt,
          hasAppleProduct: false,
        ),
        EbookPurchaseRail.freeOrExempt,
      );
    }
  });

  testWidgets(
      'iOS paid purchase never opens mobile money and refreshes ownership on success',
      (tester) async {
    final ebookProvider = _FakeEbookProvider();
    final iapProvider = _FakeIAPProvider(succeeds: true);
    await tester.pumpWidget(
      _testApp(
        service: _FakeEbookService(_paidEbook()),
        ebookProvider: ebookProvider,
        iapProvider: iapProvider,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TSh 12,000'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nunua Sasa'));
    await tester.pumpAndSettle();

    expect(find.text('Malipo ya eBook'), findsNothing);
    expect(iapProvider.ebookPurchases, 1);
    expect(ebookProvider.libraryRefreshes, 1);
    expect(ebookProvider.storeRefreshes, 1);
    expect(find.text('Library destination'), findsOneWidget);
  });

  testWidgets('Apple verification failure does not refresh or unlock content',
      (tester) async {
    final ebookProvider = _FakeEbookProvider();
    final iapProvider = _FakeIAPProvider(succeeds: false);
    await tester.pumpWidget(
      _testApp(
        service: _FakeEbookService(_paidEbook()),
        ebookProvider: ebookProvider,
        iapProvider: iapProvider,
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nunua Sasa'));
    await tester.pumpAndSettle();

    expect(find.text('Malipo ya eBook'), findsNothing);
    expect(ebookProvider.libraryRefreshes, 0);
    expect(ebookProvider.storeRefreshes, 0);
    expect(find.text('Library destination'), findsNothing);
    expect(find.text('Uthibitisho wa malipo umeshindwa.'), findsOneWidget);
  });
}
