import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/core/constants/api_endpoints.dart';
import 'package:karakana_app/core/theme/app_colors.dart';
import 'package:karakana_app/core/theme/app_theme.dart';
import 'package:karakana_app/features/zana/screens/insurance_screen.dart';
import 'package:karakana_app/features/zana/services/zana_lead_capture_service.dart';
import 'package:karakana_app/features/zana/utils/lead_capture_validators.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';

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

  testWidgets('validates required fields inline and focuses the first error',
      (tester) async {
    final service = _FakeZanaLeadCaptureService();
    await tester.pumpWidget(_app(service: service));

    await tester.ensureVisible(
      find.byKey(const Key('insurance-submit-button')),
    );
    await tester.tap(find.byKey(const Key('insurance-submit-button')));
    await tester.pump();

    expect(find.text('Weka jina lako.'), findsOneWidget);
    expect(find.text('Weka nambari ya simu.'), findsOneWidget);
    expect(service.callCount, 0);
    expect(
      _editableText(tester, const Key('insurance-name-field'))
          .focusNode
          .hasFocus,
      isTrue,
    );
  });

  testWidgets('rejects an invalid phone before submission', (tester) async {
    final service = _FakeZanaLeadCaptureService();
    await tester.pumpWidget(_app(service: service));
    await tester.enterText(
      find.byKey(const Key('insurance-name-field')),
      'Asha Mushi',
    );
    await tester.enterText(
      find.byKey(const Key('insurance-phone-field')),
      '12345',
    );

    await tester.ensureVisible(
      find.byKey(const Key('insurance-submit-button')),
    );
    await tester.tap(find.byKey(const Key('insurance-submit-button')));
    await tester.pump();

    expect(
        find.text(LeadCaptureValidators.invalidPhoneMessage), findsOneWidget);
    expect(service.callCount, 0);
  });

  testWidgets('normalizes a formatted phone before sending it', (tester) async {
    final service = _FakeZanaLeadCaptureService();
    await tester.pumpWidget(_app(service: service));
    await tester.enterText(
      find.byKey(const Key('insurance-name-field')),
      'Asha Mushi',
    );
    await tester.enterText(
      find.byKey(const Key('insurance-phone-field')),
      '+255 (712) 345-678',
    );

    await tester.ensureVisible(
      find.byKey(const Key('insurance-submit-button')),
    );
    await tester.tap(find.byKey(const Key('insurance-submit-button')));
    await tester.pumpAndSettle();

    expect(service.phone, '+255712345678');
    expect(service.callCount, 1);
  });

  testWidgets('shows a stable loading state and ignores repeated submission',
      (tester) async {
    final pendingRequest = Completer<void>();
    final service = _FakeZanaLeadCaptureService(result: pendingRequest.future);
    await tester.pumpWidget(_app(service: service));
    await _enterValidLead(tester);

    final submit = find.byKey(const Key('insurance-submit-button'));
    await tester.ensureVisible(submit);
    final idleButtonSize = tester.getSize(submit);
    await tester.tap(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(service.callCount, 1);
    expect(find.text('Inatuma...'), findsOneWidget);
    expect(find.byType(KarakanaWaveLoader), findsOneWidget);
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
    expect(tester.getSize(submit), idleButtonSize);

    pendingRequest.complete();
    await tester.pumpAndSettle();
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
    expect(
      find.byKey(const Key('insurance-submit-retry-button')),
      findsOneWidget,
    );
  });

  testWidgets('retry resubmits after a network failure', (tester) async {
    final service = _SequencedZanaLeadCaptureService([
      const ZanaLeadCaptureException(
        'Hakuna muunganisho wa intaneti. Tafadhali jaribu tena.',
      ),
      null,
    ]);
    await tester.pumpWidget(_app(service: service));
    await _enterValidLead(tester);

    await tester.ensureVisible(
      find.byKey(const Key('insurance-submit-button')),
    );
    await tester.tap(find.byKey(const Key('insurance-submit-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('insurance-submit-retry-button')),
    );
    await tester.pumpAndSettle();

    expect(service.callCount, 2);
    expect(find.byKey(const Key('insurance-submit-success')), findsOneWidget);
  });

  testWidgets('shows backend phone validation beside the phone field',
      (tester) async {
    final service = _FakeZanaLeadCaptureService(
      error: const ZanaLeadCaptureException(
        'Invalid phone.',
        fieldErrors: {
          'phone': 'Nambari ya simu si sahihi. Tumia mfano 0712345678.',
        },
      ),
    );
    await tester.pumpWidget(_app(service: service));
    await _enterValidLead(tester);

    await tester.ensureVisible(
      find.byKey(const Key('insurance-submit-button')),
    );
    await tester.tap(find.byKey(const Key('insurance-submit-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Nambari ya simu si sahihi. Tumia mfano 0712345678.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('insurance-submit-error')), findsNothing);
    expect(
      _editableText(tester, const Key('insurance-phone-field'))
          .focusNode
          .hasFocus,
      isTrue,
    );
  });

  testWidgets('unexpected failures keep the screen usable', (tester) async {
    final service = _FakeZanaLeadCaptureService(error: StateError('boom'));
    await tester.pumpWidget(_app(service: service));
    await _enterValidLead(tester);

    await tester.ensureVisible(
      find.byKey(const Key('insurance-submit-button')),
    );
    await tester.tap(find.byKey(const Key('insurance-submit-button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Imeshindikana kutuma taarifa. Tafadhali jaribu tena.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('insurance-submit-success')), findsNothing);
  });

  testWidgets('keyboard next and done actions follow the form order',
      (tester) async {
    final service = _FakeZanaLeadCaptureService();
    await tester.pumpWidget(_app(service: service));
    final name = find.byKey(const Key('insurance-name-field'));
    final phone = find.byKey(const Key('insurance-phone-field'));

    await tester.showKeyboard(name);
    await tester.enterText(name, 'Asha Mushi');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(
      _editableText(tester, const Key('insurance-phone-field'))
          .focusNode
          .hasFocus,
      isTrue,
    );

    await tester.enterText(phone, '0712345678');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(service.callCount, 1);
    expect(find.byKey(const Key('insurance-submit-success')), findsOneWidget);
  });

  testWidgets('keeps accessible labels and announces submission status',
      (tester) async {
    final pendingRequest = Completer<void>();
    final service = _FakeZanaLeadCaptureService(result: pendingRequest.future);
    await tester.pumpWidget(_app(service: service));

    const nameKey = Key('insurance-name-field');
    const phoneKey = Key('insurance-phone-field');
    final nameDecoration = tester.widget<InputDecorator>(
      find.descendant(
        of: find.byKey(nameKey),
        matching: find.byType(InputDecorator),
      ),
    );
    final phoneDecoration = tester.widget<InputDecorator>(
      find.descendant(
        of: find.byKey(phoneKey),
        matching: find.byType(InputDecorator),
      ),
    );
    expect(nameDecoration.decoration.labelText, 'Jina Lako');
    expect(phoneDecoration.decoration.labelText, 'Nambari ya Simu');
    expect(
        _editableText(tester, nameKey).textInputAction, TextInputAction.next);
    expect(
        _editableText(tester, phoneKey).textInputAction, TextInputAction.done);

    await _enterValidLead(tester);
    await tester.ensureVisible(
      find.byKey(const Key('insurance-submit-button')),
    );
    await tester.tap(find.byKey(const Key('insurance-submit-button')));
    await tester.pump();

    expect(
      tester.widgetList<Semantics>(find.byType(Semantics)).any(
            (semantics) =>
                semantics.properties.label == 'Inatuma taarifa zako' &&
                semantics.properties.liveRegion == true,
          ),
      isTrue,
    );

    pendingRequest.complete();
    await tester.pumpAndSettle();
    expect(
      tester.widgetList<Semantics>(find.byType(Semantics)).any(
            (semantics) =>
                semantics.properties.label?.startsWith('Umesajiliwa.') ==
                    true &&
                semantics.properties.liveRegion == true,
          ),
      isTrue,
    );
  });

  for (final width in [320.0, 375.0, 768.0, 1024.0]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
          'renders without overflow at ${width.toInt()} px in ${brightness.name} mode',
          (tester) async {
        tester.view.physicalSize = Size(width, width < 600 ? 844 : 1366);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _app(
            service: _FakeZanaLeadCaptureService(),
            brightness: brightness,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('insurance-name-field')), findsOneWidget);
      });
    }
  }

  testWidgets('supports large accessibility text on a 320 px screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        service: _FakeZanaLeadCaptureService(),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final subtitle = tester.renderObject<RenderParagraph>(
      find.text('Linda biashara yako dhidi ya hatari yoyote'),
    );
    expect(subtitle.didExceedMaxLines, isFalse);
  });

  for (final size in [
    const Size(568, 320),
    const Size(812, 375),
    const Size(1024, 768),
  ]) {
    testWidgets(
        'landscape ${size.width.toInt()}x${size.height.toInt()} remains overflow-free at 2x text',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _app(
          service: _FakeZanaLeadCaptureService(),
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('insurance-hero')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('keyboard inset keeps the insurance submit action reachable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        service: _FakeZanaLeadCaptureService(),
        viewInsets: const EdgeInsets.only(bottom: 260),
      ),
    );
    await tester.pumpAndSettle();

    final submit = find.byKey(const Key('insurance-submit-button'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();

    expect(submit, findsOneWidget);
    expect(tester.takeException(), isNull);
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

  test('API service exposes backend field errors cleanly', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response<Map<String, Object>>(
              requestOptions: options,
              statusCode: 400,
              data: {
                'phone': ['Enter a valid phone number.'],
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      ),
    );
    final service = ApiZanaLeadCaptureService(
      dio: dio,
      parseError: (_) => 'Ombi si sahihi.',
    );

    await expectLater(
      service.captureLead(
        name: 'Asha Mushi',
        phone: '0712345678',
        source: 'insurance',
      ),
      throwsA(
        isA<ZanaLeadCaptureException>().having(
          (error) => error.fieldErrors['phone'],
          'phone error',
          'Nambari ya simu si sahihi. Tumia mfano 0712345678.',
        ),
      ),
    );
  });

  group('LeadCaptureValidators', () {
    test('rejects blank and malformed values', () {
      expect(LeadCaptureValidators.name('   '), 'Weka jina lako.');
      expect(
        LeadCaptureValidators.phone('12345'),
        LeadCaptureValidators.invalidPhoneMessage,
      );
    });

    test('accepts backend-compatible Tanzanian phone forms', () {
      expect(LeadCaptureValidators.phone('0712345678'), isNull);
      expect(LeadCaptureValidators.phone('255712345678'), isNull);
      expect(LeadCaptureValidators.phone('+255 712 345-678'), isNull);
    });
  });
}

Widget _app({
  required ZanaLeadCaptureService service,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  AppColors.setBrightness(brightness);
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        viewInsets: viewInsets,
      ),
      child: child!,
    ),
    home: InsuranceScreen(leadCaptureService: service),
  );
}

Future<void> _enterValidLead(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('insurance-name-field')),
    'Asha Mushi',
  );
  await tester.enterText(
    find.byKey(const Key('insurance-phone-field')),
    '0712345678',
  );
}

EditableText _editableText(WidgetTester tester, Key fieldKey) {
  return tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(fieldKey),
      matching: find.byType(EditableText),
    ),
  );
}

class _FakeZanaLeadCaptureService implements ZanaLeadCaptureService {
  final Future<void>? result;
  final Object? error;

  String? name;
  String? phone;
  String? source;
  int callCount = 0;

  _FakeZanaLeadCaptureService({this.result, this.error});

  @override
  Future<void> captureLead({
    required String name,
    required String phone,
    required String source,
  }) {
    callCount += 1;
    this.name = name;
    this.phone = phone;
    this.source = source;
    if (error != null) throw error!;
    return result ?? Future<void>.value();
  }
}

class _SequencedZanaLeadCaptureService implements ZanaLeadCaptureService {
  final List<Object?> outcomes;
  int callCount = 0;

  _SequencedZanaLeadCaptureService(this.outcomes);

  @override
  Future<void> captureLead({
    required String name,
    required String phone,
    required String source,
  }) async {
    final outcome = outcomes[callCount++];
    if (outcome != null) throw outcome;
  }
}
