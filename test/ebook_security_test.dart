import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/core/utils/screenshot_prevention.dart';
import 'package:karakana_app/features/ebooks/providers/ebook_provider.dart';
import 'package:karakana_app/features/ebooks/screens/secure_ebook_reader_screen.dart';
import 'package:karakana_app/features/ebooks/services/ebook_service.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const screenshotChannel = MethodChannel('karakana/screenshot');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(screenshotChannel, null);
  });

  test('reader page cache is isolated by ebook and remains LRU-bounded',
      () async {
    final service = _FakeEbookService();
    final provider = EbookProvider(service: service);

    final firstBook = await provider.fetchReaderPage(
      ebookId: 10,
      pageNumber: 1,
    );
    final secondBook = await provider.fetchReaderPage(
      ebookId: 20,
      pageNumber: 1,
    );
    final firstBookAgain = await provider.fetchReaderPage(
      ebookId: 10,
      pageNumber: 1,
    );

    expect(firstBook, isNot(equals(secondBook)));
    expect(firstBookAgain, equals(firstBook));
    expect(service.requests, [(10, 1), (20, 1)]);
    expect(provider.pageCache.keys, containsAll([(10, 1), (20, 1)]));

    for (var page = 2; page <= 16; page++) {
      await provider.fetchReaderPage(ebookId: 10, pageNumber: page);
    }
    expect(provider.pageCache.length, 15);
  });

  test('secure display activation reports success and failure', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(screenshotChannel, (_) async => true);
    expect(await ScreenshotPrevention.enable(), isTrue);

    messenger.setMockMethodCallHandler(
      screenshotChannel,
      (_) => throw PlatformException(code: 'unavailable'),
    );
    expect(await ScreenshotPrevention.enable(), isFalse);
  });

  testWidgets('reader requests no premium page before protection is active',
      (tester) async {
    final protection = Completer<void>();
    final service = _FakeEbookService();
    final provider = EbookProvider(service: service);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(screenshotChannel, (call) async {
      if (call.method == 'enableScreenshotPrevention') {
        await protection.future;
      }
      return true;
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: SecureEbookReaderScreen(
            ebookId: 10,
            ebookTitle: 'Protected book',
          ),
        ),
      ),
    );

    expect(service.requests, isEmpty);
    protection.complete();
    await tester.pumpAndSettle();
    expect(service.requests, contains((10, 1)));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('reader fails closed when secure display cannot activate',
      (tester) async {
    final service = _FakeEbookService();
    final provider = EbookProvider(service: service);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      screenshotChannel,
      (_) => throw PlatformException(code: 'unavailable'),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: SecureEbookReaderScreen(
            ebookId: 10,
            ebookTitle: 'Protected book',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.requests, isEmpty);
    expect(
      find.text('Imeshindikana kuwasha ulinzi wa eBook kwenye kifaa hiki.'),
      findsOneWidget,
    );
  });
}

class _FakeEbookService extends EbookService {
  final List<(int ebookId, int pageNumber)> requests = [];

  static final Uint8List _transparentPixel = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );

  @override
  Future<Map<String, dynamic>> fetchPage({
    required int ebookId,
    required int pageNumber,
  }) async {
    requests.add((ebookId, pageNumber));
    return {
      'bytes': Uint8List.fromList([
        ..._transparentPixel,
        ebookId,
        pageNumber,
      ]),
      'total_pages': 20,
      'watermark_text': 'test-watermark',
      'page': pageNumber,
    };
  }
}
