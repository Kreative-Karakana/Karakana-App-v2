import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/core/constants/api_endpoints.dart';
import 'package:karakana_app/core/theme/app_colors.dart';
import 'package:karakana_app/features/zana/screens/insurance_screen.dart';
import 'package:karakana_app/features/zana/services/zana_lead_capture_service.dart';

void main() {
  testWidgets('hero uses the same deep gradient as the Zana cards',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: InsuranceScreen()),
    );

    final hero = tester.widget<Container>(
      find.byKey(const Key('insurance-hero')),
    );
    final decoration = hero.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(gradient.colors, AppColors.zanaGradient);
    expect(
      gradient.colors,
      const [
        Color(0xFF1A0A00),
        Color(0xFF3D1800),
        Color(0xFF7B3A10),
      ],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows success only after the lead request succeeds',
      (tester) async {
    final pendingRequest = Completer<void>();
    final service = _FakeZanaLeadCaptureService(
      result: pendingRequest.future,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InsuranceScreen(leadCaptureService: service),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('insurance-name-field')),
      '  Asha Mushi  ',
    );
    await tester.enterText(
      find.byKey(const Key('insurance-phone-field')),
      '  0712345678  ',
    );
    await tester.ensureVisible(
      find.byKey(const Key('insurance-submit-button')),
    );
    await tester.tap(find.byKey(const Key('insurance-submit-button')));
    await tester.pump();

    expect(service.name, 'Asha Mushi');
    expect(service.phone, '0712345678');
    expect(service.source, 'insurance');
    expect(find.byKey(const Key('insurance-submit-success')), findsNothing);

    pendingRequest.complete();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('insurance-submit-success')),
      findsOneWidget,
    );
    expect(find.text('Umesajiliwa!'), findsOneWidget);
  });

  testWidgets('keeps the form and shows an actionable error on failure',
      (tester) async {
    final service = _FakeZanaLeadCaptureService(
      error: const ZanaLeadCaptureException(
        'Hakuna muunganisho wa intaneti. Tafadhali jaribu tena.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InsuranceScreen(leadCaptureService: service),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('insurance-name-field')),
      'Asha Mushi',
    );
    await tester.enterText(
      find.byKey(const Key('insurance-phone-field')),
      '0712345678',
    );
    await tester.ensureVisible(
      find.byKey(const Key('insurance-submit-button')),
    );
    await tester.tap(find.byKey(const Key('insurance-submit-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('insurance-submit-success')), findsNothing);
    expect(find.byKey(const Key('insurance-submit-error')), findsOneWidget);
    expect(
      find.text('Hakuna muunganisho wa intaneti. Tafadhali jaribu tena.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const Key('insurance-submit-button')),
          )
          .onPressed,
      isNotNull,
    );
  });

  test('API service posts the lead contract to the backend endpoint', () async {
    late RequestOptions capturedRequest;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<void>(
              requestOptions: options,
              statusCode: 201,
            ),
          );
        },
      ),
    );
    final service = ApiZanaLeadCaptureService(dio: dio);

    await service.captureLead(
      name: 'Asha Mushi',
      phone: '0712345678',
      source: 'insurance',
    );

    expect(capturedRequest.path, ApiEndpoints.zanaLeads);
    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.data, {
      'name': 'Asha Mushi',
      'phone': '0712345678',
      'source': 'insurance',
    });
  });
}

class _FakeZanaLeadCaptureService implements ZanaLeadCaptureService {
  final Future<void>? result;
  final Object? error;

  String? name;
  String? phone;
  String? source;

  _FakeZanaLeadCaptureService({this.result, this.error});

  @override
  Future<void> captureLead({
    required String name,
    required String phone,
    required String source,
  }) {
    this.name = name;
    this.phone = phone;
    this.source = source;
    if (error != null) throw error!;
    return result ?? Future<void>.value();
  }
}
