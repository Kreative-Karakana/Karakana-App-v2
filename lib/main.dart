import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/courses/providers/course_provider.dart';
import 'providers/theme_provider.dart';

/// Must be a top-level function — called by FCM for background messages.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

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

    final token = await messaging.getToken();
    if (token != null) {
      _registerToken(token);
    }

    messaging.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen((_) {});
  }

  void _registerToken(String token) {
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Karakana',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
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
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: const Color(0xFFE87722),
              scaffoldBackgroundColor: const Color(0xFF121212),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFE87722),
                secondary: Color(0xFFFFA726),
                surface: Color(0xFF1E1E1E),
              ),
              textTheme: GoogleFonts.montserratTextTheme(
                ThemeData.dark().textTheme,
              ),
              cardColor: const Color(0xFF1E1E1E),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
