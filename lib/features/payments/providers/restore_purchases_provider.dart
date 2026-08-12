import 'package:flutter/foundation.dart';

import '../../courses/services/course_service.dart';
import '../../ebooks/services/ebook_service.dart';
import '../../subscriptions/services/subscription_service.dart';
import '../services/iap_service.dart';

enum RestoreOutcome { success, nothingToRestore, error }

/// Drives a single, global "Restore Purchases" action that recovers ALL of
/// a user's Apple non-consumables (courses, eBooks) and subscriptions on a
/// fresh install/new device.
///
/// [IAPService] only forwards a restored StoreKit transaction to the
/// backend if that product id's [IAPProductKind] was already registered
/// this session (via `loadProducts`/`purchase`) — otherwise it is shelved
/// in `_deferredPurchases` and never verified. Before calling
/// [IAPService.restorePurchases], this provider registers every product id
/// the user currently owns (or, for eBooks, has ever owned) so nothing
/// restorable is silently dropped just because the user hasn't browsed to
/// that specific course/eBook this session.
///
/// Known limitation: a course that was purchased and later unpublished or
/// blocked will not appear in `GET /api/v1/courses/?enrolled=true` (that
/// endpoint filters through `Course.optimum.visible_to()`, which excludes
/// unpublished/blocked courses regardless of enrollment), so its product id
/// cannot be preloaded here and a restore for it will not reach the
/// backend. eBooks do not share this gap — `GET /api/v1/ebooks/library/` is
/// backed by `EbookPurchase` records directly, not by the published-eBook
/// catalog, so a delisted eBook the user owns is still returned.
class RestorePurchasesProvider extends ChangeNotifier {
  final SubscriptionPurchaseStore _store;
  final CourseCatalogService _courseService;
  final EbookService _ebookService;
  final SubscriptionApi _subscriptionApi;

  RestorePurchasesProvider({
    SubscriptionPurchaseStore? store,
    CourseCatalogService? courseService,
    EbookService? ebookService,
    SubscriptionApi? subscriptionApi,
  })  : _store = store ?? IAPService.instance,
        _courseService = courseService ?? CourseService(),
        _ebookService = ebookService ?? EbookService(),
        _subscriptionApi = subscriptionApi ?? SubscriptionService();

  bool isLoading = false;
  String? errorMessage;
  RestoreOutcome? outcome;

  Future<void> restoreAll() async {
    isLoading = true;
    errorMessage = null;
    outcome = null;
    notifyListeners();

    try {
      final ready = await _store.initialize();
      if (!ready) {
        errorMessage =
            'Ununuzi wa ndani ya programu haupatikani kwenye kifaa hiki.';
        return;
      }

      final courseIds = await _ownedCourseProductIds();
      final ebookIds = await _ownedEbookProductIds();
      final subscriptionIds = await _knownSubscriptionProductIds();

      if (courseIds.isNotEmpty) {
        await _store.loadProducts(courseIds, kind: IAPProductKind.course);
      }
      if (ebookIds.isNotEmpty) {
        await _store.loadProducts(ebookIds, kind: IAPProductKind.ebook);
      }
      if (subscriptionIds.isNotEmpty) {
        await _store.loadProducts(
          subscriptionIds,
          kind: IAPProductKind.subscription,
        );
      }

      final result = await _store.restorePurchases();
      switch (result.result) {
        case IAPResult.success:
          outcome = RestoreOutcome.success;
          break;
        case IAPResult.nothingToRestore:
          outcome = RestoreOutcome.nothingToRestore;
          break;
        case IAPResult.pending:
          errorMessage = 'Malipo yanasubiri uthibitisho.';
          break;
        case IAPResult.cancelled:
          break;
        case IAPResult.error:
          errorMessage =
              result.message ?? 'Imeshindikana kurejesha ununuzi. Jaribu tena.';
          outcome = RestoreOutcome.error;
          break;
      }
    } catch (_) {
      errorMessage = 'Hitilafu ya mtandao. Jaribu tena baadaye.';
      outcome = RestoreOutcome.error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Set<String>> _ownedCourseProductIds() async {
    final ids = <String>{};
    var page = 1;
    const pageSize = 100;
    // Bounded so a backend pagination bug can never spin this loop
    // forever — no real user has anywhere near this many enrolled courses.
    const maxPages = 20;
    try {
      while (page <= maxPages) {
        final result = await _courseService.getCoursesPage(
          enrolled: true,
          page: page,
          pageSize: pageSize,
        );
        for (final course in result.items) {
          final productId = course.appleIapProductId;
          if (productId != null && productId.isNotEmpty) {
            ids.add(productId);
          }
        }
        if (!result.hasNext) break;
        page += 1;
      }
    } catch (_) {
      // Best effort — a failed course fetch must not block eBook/
      // subscription restore from proceeding.
    }
    return ids;
  }

  Future<Set<String>> _ownedEbookProductIds() async {
    try {
      final purchases = await _ebookService.fetchLibrary();
      return {
        for (final purchase in purchases)
          if (purchase.isSuccessful &&
              (purchase.ebook.appleIapProductId?.isNotEmpty ?? false))
            purchase.ebook.appleIapProductId!,
      };
    } catch (_) {
      return {};
    }
  }

  Future<Set<String>> _knownSubscriptionProductIds() async {
    try {
      final plans = await _subscriptionApi.getPlans();
      return {
        for (final plan in plans)
          if (plan.appleIapProductId != null &&
              plan.appleIapProductId!.isNotEmpty)
            plan.appleIapProductId!,
      };
    } catch (_) {
      return {};
    }
  }

  void reset() {
    isLoading = false;
    errorMessage = null;
    outcome = null;
    notifyListeners();
  }
}
