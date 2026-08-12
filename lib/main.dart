import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'firebase_options.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/courses/providers/course_provider.dart';
import 'features/courses/providers/quiz_attempt_provider.dart';
import 'features/ebooks/providers/ebook_provider.dart';
import 'features/fursa/providers/fursa_provider.dart';
import 'features/payments/providers/iap_provider.dart';
import 'features/payments/providers/restore_purchases_provider.dart';
import 'features/payments/services/iap_service.dart';

/// Must be a top-level function — called by FCM for background messages.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[FCM] Background Firebase init skipped: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    try {
      Firebase.app();
      firebaseReady = true;
    } catch (_) {
      debugPrint('[Firebase] Initialization failed: $e');
    }
  }

  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  } else {
    debugPrint(
        '[FCM] Background handler not registered because Firebase is unavailable.');
  }

  final authProvider = AuthProvider();
  try {
    await authProvider.initialize();
  } catch (e) {
    debugPrint('AuthProvider init error: $e');
  }

  // Start StoreKit/Play transaction observation before any purchase screen
  // opens. Unfinished transactions can then be verified after relaunch; the
  // service only finishes them once backend persistence succeeds.
  try {
    await IAPService.instance.initialize();
  } catch (e) {
    debugPrint('[IAP] Startup initialization deferred: $e');
  }

  final themeProvider = ThemeProvider();
  try {
    await themeProvider.initialize();
  } catch (e) {
    debugPrint('ThemeProvider init error: $e');
  }

  runApp(KarakanaApp(
    authProvider: authProvider,
    themeProvider: themeProvider,
    firebaseReady: firebaseReady,
  ));
}

class KarakanaApp extends StatefulWidget {
  final AuthProvider authProvider;
  final ThemeProvider themeProvider;
  final bool firebaseReady;
  const KarakanaApp({
    super.key,
    required this.authProvider,
    required this.themeProvider,
    required this.firebaseReady,
  });

  @override
  State<KarakanaApp> createState() => _KarakanaAppState();
}

class _KarakanaAppState extends State<KarakanaApp> with WidgetsBindingObserver {
  late final router = AppRouter.createRouter(widget.authProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.firebaseReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initFCM());
    } else {
      debugPrint('[FCM] Startup setup skipped because Firebase is not ready.');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    widget.themeProvider.handlePlatformBrightnessChanged(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
  }

  Future<void> _initFCM() async {
    try {
      Firebase.app();
    } catch (e) {
      debugPrint('[FCM] Startup setup skipped: no Firebase app available ($e)');
      return;
    }

    final messaging = FirebaseMessaging.instance;
    try {
      // Request permission after first frame so app startup is not blocked.
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[FCM] Permission request failed: $e');
    }

    try {
      final token = await messaging.getToken();
      if (token != null) {
        _registerToken(token);
      }
    } catch (e) {
      debugPrint('[FCM] Token retrieval skipped: $e');
    }

    messaging.onTokenRefresh.listen(
      _registerToken,
      onError: (Object error) {
        debugPrint('[FCM] Token refresh listener error: $error');
      },
    );

    FirebaseMessaging.onMessage.listen((_) {});
  }

  void _registerToken(String token) {
    // Token registration is handled by auth endpoints in current backend.
    // Skip standalone registration call to avoid noisy 404s on boot.
    debugPrint('[FCM] Token captured (length=${token.length})');
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: widget.authProvider),
            ChangeNotifierProvider.value(value: widget.themeProvider),
            ChangeNotifierProvider(create: (_) => CourseProvider()),
            ChangeNotifierProvider(create: (_) => QuizAttemptProvider()),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProvider(create: (_) => EbookProvider()),
            ChangeNotifierProvider(create: (_) => FursaProvider()),
            ChangeNotifierProvider(create: (_) => IAPProvider()),
            ChangeNotifierProvider(create: (_) => RestorePurchasesProvider()),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return MaterialApp.router(
                title: 'Karakana',
                debugShowCheckedModeBanner: false,
                themeMode: themeProvider.themeMode,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                routerConfig: router,
              );
            },
          ),
        );
      },
    );
  }
}
