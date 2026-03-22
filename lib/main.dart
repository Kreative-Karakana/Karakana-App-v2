import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/courses/providers/course_provider.dart';

/// Entry point.
///
/// Initialises environment variables and the auth session before handing
/// control to [KarakanaApp]. The [AuthProvider] is created here so it can be
/// passed into [KarakanaApp] and used to build the router exactly once.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (_) {
    // .env is optional in development — silently continue.
  }

  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(KarakanaApp(authProvider: authProvider));
}

/// Root application widget.
///
/// [KarakanaApp] is a [StatefulWidget] so that the [GoRouter] can be
/// created once in [initState] and stored as a `late final` field.
///
/// The critical fix: the router must never be recreated inside a build or
/// Consumer callback. Doing so caused every [AuthProvider.notifyListeners]
/// call (including the one triggered by [clearError] on each keystroke) to
/// produce a brand-new router, resetting the entire navigation stack to the
/// splash screen.
class KarakanaApp extends StatefulWidget {
  const KarakanaApp({super.key, required this.authProvider});

  final AuthProvider authProvider;

  @override
  State<KarakanaApp> createState() => _KarakanaAppState();
}

class _KarakanaAppState extends State<KarakanaApp> {
  /// Created once in [initState] and never recreated.
  ///
  /// [AppRouter.createRouter] accepts the [AuthProvider] so that the router
  /// can set [GoRouter.refreshListenable] and evaluate redirect logic — but
  /// the router object itself is stable for the entire lifetime of the app.
  late final _router = AppRouter.createRouter(widget.authProvider);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Expose the pre-initialised AuthProvider to the whole widget tree.
        ChangeNotifierProvider.value(value: widget.authProvider),

        // CourseProvider is independent and can be created lazily here.
        ChangeNotifierProvider(create: (_) => CourseProvider()),
      ],
      child: MaterialApp.router(
        title: 'Karakana',
        theme: AppTheme.theme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
