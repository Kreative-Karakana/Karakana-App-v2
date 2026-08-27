import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normal app orientation is locked to portrait', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });

    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await configureAppOrientation();

    final orientationCall = calls.singleWhere(
      (call) => call.method == 'SystemChrome.setPreferredOrientations',
    );
    expect(orientationCall.arguments, ['DeviceOrientation.portraitUp']);
  });
}
