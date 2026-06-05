import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions has not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions is only configured for Android and iOS.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD42Y-P5tq07AnBLhDyE1XlPoz7O-Mfark',
    appId: '1:466490006316:android:27a3dc2638200c30656a89',
    messagingSenderId: '466490006316',
    projectId: 'karakana-app',
    storageBucket: 'karakana-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBIPLE8zChLji9jYAwPSRetWIQpqVRilvs',
    appId: '1:466490006316:ios:beb6990b4324a8e4656a89',
    messagingSenderId: '466490006316',
    projectId: 'karakana-app',
    storageBucket: 'karakana-app.firebasestorage.app',
    iosBundleId: 'com.kreativekarakana.karakana',
  );
}
