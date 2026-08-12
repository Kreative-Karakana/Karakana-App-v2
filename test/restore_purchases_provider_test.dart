import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:karakana_app/features/courses/models/course_model.dart';
import 'package:karakana_app/features/courses/services/course_service.dart';
import 'package:karakana_app/features/ebooks/models/ebook.dart';
import 'package:karakana_app/features/ebooks/services/ebook_service.dart';
import 'package:karakana_app/features/payments/providers/restore_purchases_provider.dart';
import 'package:karakana_app/features/payments/services/iap_service.dart';
import 'package:karakana_app/features/subscriptions/models/entitlement_status.dart';
import 'package:karakana_app/features/subscriptions/models/subscription_plan.dart';

import 'support/fake_subscription_api.dart';

const courseProduct = 'com.kreativekarakana.karakana.course.vicoba';
const ebookProduct = 'com.kreativekarakana.karakana.ebook.biashara';
const subscriptionProduct =
    'com.kreativekarakana.karakana.subscription.monthly';

void main() {
  group('RestorePurchasesProvider', () {
    test(
        'registers every owned course/eBook/subscription product id before '
        'calling restorePurchases, so nothing is silently deferred', () async {
      final store = _RecordingStore();
      final provider = RestorePurchasesProvider(
        store: store,
        courseService: _FakeCourseService([_course(1, courseProduct)]),
        ebookService: _FakeEbookService([_purchase(ebookProduct)]),
        subscriptionApi: FakeSubscriptionApi(
          plans: [_plan(subscriptionProduct)],
        ),
      );

      await provider.restoreAll();

      expect(store.registeredKinds[courseProduct], IAPProductKind.course);
      expect(store.registeredKinds[ebookProduct], IAPProductKind.ebook);
      expect(
        store.registeredKinds[subscriptionProduct],
        IAPProductKind.subscription,
      );

      // IAPService only forwards a restored transaction to the backend if
      // its product id's kind was already registered — every loadProducts
      // call must therefore happen before restorePurchases() fires.
      final restoreIndex = store.calls.indexOf('restorePurchases');
      expect(restoreIndex, greaterThan(-1));
      for (final id in [courseProduct, ebookProduct, subscriptionProduct]) {
        final loadIndex = store.calls.indexWhere(
          (c) => c.startsWith('loadProducts:') && c.contains(id),
        );
        expect(
          loadIndex,
          allOf(greaterThanOrEqualTo(0), lessThan(restoreIndex)),
          reason: '$id should be registered before restore is triggered',
        );
      }
      expect(provider.outcome, RestoreOutcome.success);
      expect(provider.errorMessage, isNull);
    });

    test(
      'registers every id from authenticated course restore discovery',
      () async {
        final store = _RecordingStore();
        final service = _FakeCourseService(
          [_course(1, 'course.page-one')],
          secondPage: [_course(2, 'course.page-two')],
        );
        final provider = RestorePurchasesProvider(
          store: store,
          courseService: service,
          ebookService: _FakeEbookService(const []),
          subscriptionApi: FakeSubscriptionApi(plans: const []),
        );

        await provider.restoreAll();

        expect(store.registeredKinds['course.page-one'], IAPProductKind.course);
        expect(store.registeredKinds['course.page-two'], IAPProductKind.course);
        expect(service.restoreProductCalls, 1);
      },
    );

    test(
        'only registers eBooks from successful purchases that have a '
        'configured Apple product id', () async {
      final store = _RecordingStore();
      final provider = RestorePurchasesProvider(
        store: store,
        courseService: _FakeCourseService(const []),
        ebookService: _FakeEbookService([
          _purchase(ebookProduct, id: 1),
          _purchase(null, id: 2),
          _purchase('failed.purchase', id: 3, successful: false),
        ]),
        subscriptionApi: FakeSubscriptionApi(plans: const []),
      );

      await provider.restoreAll();

      expect(store.registeredKinds.keys, [ebookProduct]);
    });

    test(
      'reports nothingToRestore when the store has nothing to restore',
      () async {
        final store = _RecordingStore()
          ..restoreResult = const IAPPurchaseResult(IAPResult.nothingToRestore);
        final provider = RestorePurchasesProvider(
          store: store,
          courseService: _FakeCourseService(const []),
          ebookService: _FakeEbookService(const []),
          subscriptionApi: FakeSubscriptionApi(plans: const []),
        );

        await provider.restoreAll();

        expect(provider.outcome, RestoreOutcome.nothingToRestore);
        expect(provider.errorMessage, isNull);
      },
    );

    test(
        'surfaces a store initialization failure without calling '
        'restorePurchases', () async {
      final store = _RecordingStore()..available = false;
      final provider = RestorePurchasesProvider(
        store: store,
        courseService: _FakeCourseService(const []),
        ebookService: _FakeEbookService(const []),
        subscriptionApi: FakeSubscriptionApi(plans: const []),
      );

      await provider.restoreAll();

      expect(provider.outcome, isNull);
      expect(provider.errorMessage, isNotNull);
      expect(store.calls, ['initialize']);
    });

    test(
      'a failing course fetch does not block eBook/subscription restore',
      () async {
        final store = _RecordingStore();
        final provider = RestorePurchasesProvider(
          store: store,
          courseService: _ThrowingCourseService(),
          ebookService: _FakeEbookService([_purchase(ebookProduct)]),
          subscriptionApi: FakeSubscriptionApi(
            plans: [_plan(subscriptionProduct)],
          ),
        );

        await provider.restoreAll();

        expect(store.registeredKinds[ebookProduct], IAPProductKind.ebook);
        expect(
          store.registeredKinds[subscriptionProduct],
          IAPProductKind.subscription,
        );
        expect(provider.outcome, RestoreOutcome.success);
      },
    );

    test(
      'registers a retired subscription plan from entitlement history',
      () async {
        final store = _RecordingStore();
        final retiredPlan = _plan('subscription.retired');
        final provider = RestorePurchasesProvider(
          store: store,
          courseService: _FakeCourseService(const []),
          ebookService: _FakeEbookService(const []),
          subscriptionApi: FakeSubscriptionApi(
            plans: const [],
            status: EntitlementStatus(
              hasActiveSubscription: true,
              trialEligible: false,
              status: 'active',
              expiryDate: null,
              plan: retiredPlan,
            ),
          ),
        );

        await provider.restoreAll();

        expect(
          store.registeredKinds['subscription.retired'],
          IAPProductKind.subscription,
        );
      },
    );
  });
}

CourseModel _course(int id, String appleProductId) => CourseModel(
      id: id,
      title: 'Course $id',
      excerpt: '',
      description: '',
      price: 0,
      status: 'published',
      level: 'beginner',
      appleIapProductId: appleProductId,
      trainerName: '',
      trainerId: 0,
      studentCount: 0,
      averageRating: 0,
      reviewCount: 0,
      isEnrolled: true,
      isWishlisted: false,
      categories: const [],
      faqs: const [],
    );

Ebook _ebook(String? appleProductId, {int id = 1}) => Ebook(
      id: id,
      title: 'Ebook $id',
      description: '',
      authorName: '',
      coverImageUrl: null,
      priceInTzs: 1000,
      totalPages: 10,
      isPurchased: true,
      isPaymentExempt: false,
      appleIapProductId: appleProductId,
      status: 'published',
      buyersCount: 0,
      successfulPurchasesCount: 0,
      totalRevenue: 0,
      createdAt: null,
      updatedAt: null,
    );

EbookPurchase _purchase(
  String? appleProductId, {
  int id = 1,
  bool successful = true,
}) =>
    EbookPurchase(
      id: id,
      ebook: _ebook(appleProductId, id: id),
      externalId: 'ext-$id',
      isSuccessful: successful,
      checkoutResponse: null,
    );

SubscriptionPlan _plan(String appleProductId) => SubscriptionPlan(
      id: 1,
      name: 'Monthly',
      slug: 'monthly',
      billingPeriod: 'monthly',
      durationDays: 30,
      price: '29900',
      currency: 'TZS',
      features: const [],
      appleIapProductId: appleProductId,
    );

class _RecordingStore implements SubscriptionPurchaseStore {
  bool available = true;
  IAPPurchaseResult restoreResult = const IAPPurchaseResult(IAPResult.success);
  final Map<String, IAPProductKind> registeredKinds = {};
  final List<String> calls = [];

  @override
  Future<bool> initialize() async {
    calls.add('initialize');
    return available;
  }

  @override
  Future<void> loadProducts(
    Set<String> productIds, {
    IAPProductKind? kind,
  }) async {
    calls.add('loadProducts:${kind?.name ?? "none"}:${productIds.join(",")}');
    if (kind != null) {
      for (final id in productIds) {
        registeredKinds[id] = kind;
      }
    }
  }

  @override
  ProductDetails? getProduct(String productId) => null;

  @override
  StoreProductPresentation? getSubscriptionPresentation(String productId) =>
      null;

  @override
  Future<IAPPurchaseResult> purchase(
    String productId, {
    IAPProductKind kind = IAPProductKind.course,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<IAPPurchaseResult> restorePurchases() async {
    calls.add('restorePurchases');
    return restoreResult;
  }
}

class _FakeEbookService extends EbookService {
  _FakeEbookService(this._library);
  final List<EbookPurchase> _library;

  @override
  Future<List<EbookPurchase>> fetchLibrary() async => _library;
}

class _FakeCourseService implements CourseCatalogService {
  _FakeCourseService(this.firstPage, {this.secondPage = const []});

  final List<CourseModel> firstPage;
  final List<CourseModel> secondPage;
  final List<int> requestedPages = [];
  int restoreProductCalls = 0;

  @override
  Future<Set<String>> getAppleRestoreProductIds() async {
    restoreProductCalls += 1;
    return {
      for (final course in [...firstPage, ...secondPage])
        if (course.appleIapProductId?.isNotEmpty ?? false)
          course.appleIapProductId!,
    };
  }

  @override
  Future<PaginatedCourses> getCoursesPage({
    String? search,
    String? categoryName,
    bool? recommended,
    bool? popular,
    bool? free,
    bool? weeklyChoice,
    bool? enrolled,
    int page = 1,
    int pageSize = 20,
  }) async {
    requestedPages.add(page);
    if (enrolled != true) {
      return const PaginatedCourses(
        items: [],
        count: 0,
        next: null,
        previous: null,
      );
    }
    if (page == 1) {
      return PaginatedCourses(
        items: firstPage,
        count: firstPage.length + secondPage.length,
        next: secondPage.isNotEmpty ? 'https://example.test/?page=2' : null,
        previous: null,
      );
    }
    if (page == 2 && secondPage.isNotEmpty) {
      return PaginatedCourses(
        items: secondPage,
        count: firstPage.length + secondPage.length,
        next: null,
        previous: 'https://example.test/?page=1',
      );
    }
    return const PaginatedCourses(
      items: [],
      count: 0,
      next: null,
      previous: null,
    );
  }

  @override
  Future<List<CourseModel>> getCourses({
    String? search,
    String? categoryName,
    bool? recommended,
    bool? popular,
    bool? free,
    bool? weeklyChoice,
    bool? enrolled,
    int pageSize = 20,
  }) async =>
      firstPage;

  @override
  Future<CourseModel> getCourseDetail(int id) => throw UnimplementedError();

  @override
  Future<List<CategoryModel>> getCategories() => throw UnimplementedError();

  @override
  Future<List<SectionModel>> getCourseSections(int courseId) =>
      throw UnimplementedError();

  @override
  Future<bool> toggleLessonProgress(int lessonId) => throw UnimplementedError();

  @override
  Future<bool> enrollFreeCourse(int courseId) => throw UnimplementedError();

  @override
  Future<bool> toggleWishlist(int courseId) => throw UnimplementedError();

  @override
  Future<List<ReviewModel>> getCourseReviews(int courseId) =>
      throw UnimplementedError();

  @override
  Future<List<BannerModel>> getBanners() => throw UnimplementedError();
}

class _ThrowingCourseService implements CourseCatalogService {
  @override
  Future<Set<String>> getAppleRestoreProductIds() async {
    throw Exception('network error');
  }

  @override
  Future<PaginatedCourses> getCoursesPage({
    String? search,
    String? categoryName,
    bool? recommended,
    bool? popular,
    bool? free,
    bool? weeklyChoice,
    bool? enrolled,
    int page = 1,
    int pageSize = 20,
  }) async {
    throw Exception('network error');
  }

  @override
  Future<List<CourseModel>> getCourses({
    String? search,
    String? categoryName,
    bool? recommended,
    bool? popular,
    bool? free,
    bool? weeklyChoice,
    bool? enrolled,
    int pageSize = 20,
  }) async =>
      throw Exception('network error');

  @override
  Future<CourseModel> getCourseDetail(int id) => throw UnimplementedError();

  @override
  Future<List<CategoryModel>> getCategories() => throw UnimplementedError();

  @override
  Future<List<SectionModel>> getCourseSections(int courseId) =>
      throw UnimplementedError();

  @override
  Future<bool> toggleLessonProgress(int lessonId) => throw UnimplementedError();

  @override
  Future<bool> enrollFreeCourse(int courseId) => throw UnimplementedError();

  @override
  Future<bool> toggleWishlist(int courseId) => throw UnimplementedError();

  @override
  Future<List<ReviewModel>> getCourseReviews(int courseId) =>
      throw UnimplementedError();

  @override
  Future<List<BannerModel>> getBanners() => throw UnimplementedError();
}
