import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/courses/providers/course_provider.dart';

/// Must be a top-level function — called by FCM for background messages.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are handled by the OS notification tray.
  // No extra work needed here for now.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // Request permission (iOS / Android 13+)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(KarakanaApp(authProvider: authProvider));
}

class KarakanaApp extends StatefulWidget {
  final AuthProvider authProvider;
  const KarakanaApp({super.key, required this.authProvider});

  @override
  State<KarakanaApp> createState() => _KarakanaAppState();
}

class _KarakanaAppState extends State<KarakanaApp> {
  late final router = AppRouter.createRouter(widget.authProvider);

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    final messaging = FirebaseMessaging.instance;

    // Register device token with backend when user is logged in
    final token = await messaging.getToken();
    if (token != null) {
      _registerToken(token);
    }

    // Refresh token listener
    messaging.onTokenRefresh.listen(_registerToken);

    // Foreground message handler — show a snackbar / in-app banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Refresh notifications badge in the app
      // The NotificationProvider will be notified via its own load call
      // triggered by the notification screen. No extra work needed here.
    });
  }

  void _registerToken(String token) {
    // Best-effort — don't block startup if this fails
    ApiClient().dio.post(
      '/api/v1/accounts/fcm-token/',
      data: {'token': token},
    ).then((_) {}).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp.router(
        title: 'Karakana',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        routerConfig: router,
      ),
    );
  }
}
