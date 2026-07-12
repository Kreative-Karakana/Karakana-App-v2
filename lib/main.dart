import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/courses/providers/course_provider.dart';
import 'features/courses/providers/quiz_attempt_provider.dart';
import 'features/ebooks/providers/ebook_provider.dart';
import 'features/fursa/providers/fursa_provider.dart';
import 'features/payments/providers/iap_provider.dart';

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

  runApp(KarakanaApp(
    authProvider: authProvider,
    firebaseReady: firebaseReady,
  ));
}

class KarakanaApp extends StatefulWidget {
  final AuthProvider authProvider;
  final bool firebaseReady;
  const KarakanaApp({
    super.key,
    required this.authProvider,
    required this.firebaseReady,
  });

  @override
  State<KarakanaApp> createState() => _KarakanaAppState();
}

class _KarakanaAppState extends State<KarakanaApp> {
  late final router = AppRouter.createRouter(widget.authProvider);

  @override
  void initState() {
    super.initState();
    if (widget.firebaseReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initFCM());
    } else {
      debugPrint('[FCM] Startup setup skipped because Firebase is not ready.');
    }
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
            ChangeNotifierProvider(create: (_) => CourseProvider()),
            ChangeNotifierProvider(create: (_) => QuizAttemptProvider()),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProvider(create: (_) => EbookProvider()),
            ChangeNotifierProvider(create: (_) => FursaProvider()),
            ChangeNotifierProvider(create: (_) => IAPProvider()),
          ],
          child: MaterialApp.router(
            title: 'Karakana',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.light,
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: const Color(0xFFE87722),
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFE87722),
                secondary: Color(0xFF3D1800),
                surface: Colors.white,
              ),
              textTheme: GoogleFonts.montserratTextTheme(
                ThemeData.light().textTheme,
              ),
              cardColor: Colors.white,
              iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
            ),
            routerConfig: router,
          ),
        );
      },
    );
  }
}
