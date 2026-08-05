import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/fursa/widgets/fursa_thumbnail.dart';

Widget _app({
  required String? imageUrl,
  ThemeMode themeMode = ThemeMode.light,
  double width = 320,
}) {
  return MaterialApp(
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: themeMode,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: FursaThumbnail(
            imageUrl: imageUrl,
            semanticLabel: 'Fursa ya majaribio',
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('missing image uses a stable 16:9 placeholder', (tester) async {
    await tester.pumpWidget(_app(imageUrl: null));

    expect(find.byKey(FursaThumbnail.missingPlaceholderKey), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
    final ratio = tester.widget<AspectRatio>(find.byType(AspectRatio));
    expect(ratio.aspectRatio, 16 / 9);
  });

  testWidgets('blank image URL is handled as missing content', (tester) async {
    await tester.pumpWidget(_app(imageUrl: '   '));

    expect(find.byKey(FursaThumbnail.missingPlaceholderKey), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('valid image uses cached loading and cover cropping',
      (tester) async {
    const url = 'https://example.test/fursa.jpg';
    await tester.pumpWidget(_app(imageUrl: url));

    final finder = find.byType(CachedNetworkImage);
    expect(finder, findsOneWidget);
    final image = tester.widget<CachedNetworkImage>(finder);
    expect(image.imageUrl, url);
    expect(image.fit, BoxFit.cover);
    expect(image.memCacheWidth, greaterThan(0));

    final loading = image.placeholder!(tester.element(finder), url);
    await tester.pumpWidget(MaterialApp(home: loading));
    expect(find.byKey(FursaThumbnail.loadingPlaceholderKey), findsOneWidget);
  });

  testWidgets('broken image callback returns the clean error placeholder',
      (tester) async {
    const url = 'https://example.test/broken.jpg';
    await tester.pumpWidget(_app(imageUrl: url));

    final finder = find.byType(CachedNetworkImage);
    final image = tester.widget<CachedNetworkImage>(finder);
    final error = image.errorWidget!(
      tester.element(finder),
      url,
      StateError('broken image'),
    );

    await tester.pumpWidget(MaterialApp(home: error));
    expect(find.byKey(FursaThumbnail.errorPlaceholderKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('placeholder renders in dark mode on a small card',
      (tester) async {
    await tester.pumpWidget(
      _app(imageUrl: null, themeMode: ThemeMode.dark, width: 76),
    );

    expect(find.byKey(FursaThumbnail.missingPlaceholderKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
