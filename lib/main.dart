import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/courses/providers/course_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  late final router =
      AppRouter.createRouter(widget.authProvider);

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
