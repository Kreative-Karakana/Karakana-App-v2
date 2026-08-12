import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:karakana_app/features/auth/providers/auth_provider.dart';
import 'package:karakana_app/features/courses/providers/course_provider.dart';
import 'package:karakana_app/features/courses/screens/course_reviews_screen.dart';
import 'package:karakana_app/features/courses/services/review_safety_service.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('report action submits and shows a clear success state',
      (tester) async {
    final safety = _FakeSafetyService();
    await _pumpScreen(tester, safety: safety);

    await tester.tap(find.byTooltip('Chaguo za usalama'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ripoti tathmini'));
    await tester.pumpAndSettle();
    expect(find.text('Ripoti tathmini'), findsOneWidget);

    await tester.tap(find.text('Tuma Ripoti'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(safety.reportCalls, 1);
    expect(safety.lastTarget, ReviewTargetPart.review);
    expect(
      find.textContaining('Ripoti yako imetumwa'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('report failure stays in context and never shows a raw error',
      (tester) async {
    final safety = _FakeSafetyService()..failReport = true;
    await _pumpScreen(tester, safety: safety);

    await tester.tap(find.byTooltip('Chaguo za usalama'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ripoti tathmini'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tuma Ripoti'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(safety.reportCalls, 1);
    expect(find.textContaining('Imeshindikana kutuma ripoti'), findsOneWidget);
    expect(find.textContaining('backend-stack-trace'), findsNothing);
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('block requires confirmation and reloads suppressed content',
      (tester) async {
    final safety = _FakeSafetyService();
    var blocked = false;
    var loads = 0;
    await _pumpScreen(
      tester,
      safety: safety,
      loader: () async {
        loads += 1;
        return [_review(blocked: blocked)];
      },
    );

    await tester.tap(find.byTooltip('Chaguo za usalama'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zuia mtumiaji'));
    await tester.pumpAndSettle();
    expect(find.text('Zuia mtumiaji?'), findsOneWidget);
    blocked = true;
    await tester.tap(find.text('Zuia'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(safety.blockCalls, 1);
    expect(loads, 2);
    expect(find.textContaining('Maudhui ya mtumiaji huyu yamefichwa'),
        findsOneWidget);
    expect(find.text('Maudhui yanayoripotiwa'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('blocked placeholder exposes unblock and restores visibility',
      (tester) async {
    final safety = _FakeSafetyService();
    var blocked = true;
    await _pumpScreen(
      tester,
      safety: safety,
      loader: () async => [_review(blocked: blocked)],
    );

    await tester.tap(find.byTooltip('Chaguo za usalama'));
    await tester.pumpAndSettle();
    blocked = false;
    await tester.tap(find.text('Ondoa zuio la mtumiaji'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(safety.unblockCalls, 1);
    expect(find.text('Maudhui yanayoripotiwa'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeSafetyService safety,
  Future<List<dynamic>> Function()? loader,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
      ],
      child: MaterialApp(
        home: CourseReviewsScreen(
          courseId: 7,
          safetyService: safety,
          reviewLoader: loader ?? () async => [_review()],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Map<String, dynamic> _review({bool blocked = false}) => {
      'id': 11,
      'student':
          blocked ? null : {'id': 2, 'first_name': 'Asha', 'last_name': 'Juma'},
      'rating': blocked ? 0 : 4,
      'content': blocked ? '' : 'Maudhui yanayoripotiwa',
      'reply': 'Asante kwa maoni',
      'is_owner': false,
      'is_trainer': false,
      'has_trainer_reply': true,
      'is_review_author_blocked': blocked,
      'is_reply_author_blocked': false,
    };

class _FakeSafetyService extends ReviewSafetyService {
  _FakeSafetyService() : super(dio: Dio());

  int reportCalls = 0;
  int blockCalls = 0;
  int unblockCalls = 0;
  bool failReport = false;
  ReviewTargetPart? lastTarget;

  @override
  Future<void> report({
    required int courseId,
    required int reviewId,
    required ReviewTargetPart targetPart,
    required ReviewReportReason reason,
    String detail = '',
  }) async {
    reportCalls += 1;
    lastTarget = targetPart;
    if (failReport) throw Exception('backend-stack-trace');
  }

  @override
  Future<void> block({
    required int courseId,
    required int reviewId,
    required ReviewTargetPart targetPart,
  }) async {
    blockCalls += 1;
    lastTarget = targetPart;
  }

  @override
  Future<void> unblock({
    required int courseId,
    required int reviewId,
    required ReviewTargetPart targetPart,
  }) async {
    unblockCalls += 1;
    lastTarget = targetPart;
  }
}
