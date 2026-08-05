import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/widgets/common/fullscreen_video_orientation.dart';

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with FullscreenVideoOrientation {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  List<MethodCall> orientationCalls() => calls
      .where((c) => c.method == 'SystemChrome.setPreferredOrientations')
      .toList();

  testWidgets(
      'enterFullscreenOrientation resets to unrestricted, waits for iOS to '
      'settle, then locks landscape (regression: iOS UISceneErrorDomain 101 '
      'when a restrictive orientation is requested before UIKit has '
      'processed the reset — confirmed via device testing)', (tester) async {
    await tester.pumpWidget(const _Host());
    final state = tester.state<_HostState>(find.byType(_Host));

    final future = state.enterFullscreenOrientation();

    await tester.pump();
    expect(orientationCalls(), hasLength(1),
        reason: 'must reset to unrestricted first');
    expect(orientationCalls()[0].arguments, isEmpty);

    await tester.pump(const Duration(milliseconds: 60));
    expect(orientationCalls(), hasLength(1),
        reason: 'must not lock landscape before the settle delay elapses');

    await tester.pump(const Duration(milliseconds: 100));
    await future;
    final requests = orientationCalls();
    expect(requests, hasLength(2));
    expect(
      requests[1].arguments,
      containsAll([
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight'
      ]),
    );
    expect(
      calls.any((c) => c.method == 'SystemChrome.setEnabledSystemUIMode'),
      isTrue,
    );
  });

  testWidgets(
      'restorePortraitOrientation resets to unrestricted, waits for iOS to '
      'settle, then locks portrait — even though this is typically called '
      'from dispose(), where mounted is already false by the time the '
      'settle delay elapses', (tester) async {
    await tester.pumpWidget(const _Host());
    final state = tester.state<_HostState>(find.byType(_Host));

    final future = state.restorePortraitOrientation();

    await tester.pump();
    expect(orientationCalls(), hasLength(1));
    expect(orientationCalls()[0].arguments, isEmpty);

    await tester.pump(const Duration(milliseconds: 60));
    expect(orientationCalls(), hasLength(1),
        reason: 'must not lock portrait before the settle delay elapses — '
            'this is exactly the gap that left the whole app stuck in '
            'landscape on-device');

    await tester.pump(const Duration(milliseconds: 100));
    await future;
    final requests = orientationCalls();
    expect(requests, hasLength(2));
    expect(requests[1].arguments, ['DeviceOrientation.portraitUp']);
    expect(
      calls.any((c) => c.method == 'SystemChrome.setEnabledSystemUIMode'),
      isTrue,
    );
  });

  testWidgets(
      'restorePortraitOrientation still locks portrait when the widget is '
      'no longer mounted by the time the settle delay elapses (mirrors '
      'being called from dispose())', (tester) async {
    await tester.pumpWidget(const _Host());
    final state = tester.state<_HostState>(find.byType(_Host));

    final future = state.restorePortraitOrientation();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(state.mounted, isFalse);

    await tester.pump(const Duration(milliseconds: 200));
    await future;

    final requests = orientationCalls();
    expect(requests, hasLength(2));
    expect(requests[1].arguments, ['DeviceOrientation.portraitUp']);
  });

  testWidgets(
      'restorePortraitOrientation is idempotent — a second call (e.g. from '
      'both PopScope and dispose) makes no further platform calls',
      (tester) async {
    await tester.pumpWidget(const _Host());
    final state = tester.state<_HostState>(find.byType(_Host));

    final first = state.restorePortraitOrientation();
    await tester.pump(const Duration(milliseconds: 200));
    await first;
    final callCountAfterFirst = calls.length;

    await state.restorePortraitOrientation();

    expect(calls.length, callCountAfterFirst,
        reason: 'a second restore call must not race a fresh platform call '
            'against the first, which is what let rapid fullscreen '
            'toggling get the app stuck in landscape');
  });
}
