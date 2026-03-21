import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/courses/providers/course_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (e) {
    debugPrint('Warning: could not load .env file: $e');
  }

  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(KarakanaApp(authProvider: authProvider));
}

class KarakanaApp extends StatelessWidget {
  const KarakanaApp({super.key, required this.authProvider});

  final AuthProvider authProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final router = AppRouter.createRouter(auth);

          return MaterialApp.router(
            title: 'Karakana',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
