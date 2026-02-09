import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Services/auth_service.dart';
import 'Utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Auth Service and restore session if exists
  await AuthService().initialize();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const CivicSightApp());
}

class CivicSightApp extends StatefulWidget {
  const CivicSightApp({super.key});

  @override
  State<CivicSightApp> createState() => _CivicSightAppState();
}

class _CivicSightAppState extends State<CivicSightApp> {
  // Compute initial route once, not on every rebuild
  late final String _initialRoute;

  @override
  void initState() {
    super.initState();
    final authService = AuthService();
    if (!authService.isLoggedIn) {
      _initialRoute = AppRouter.login;
    } else if (authService.needsProfileSetup) {
      _initialRoute = AppRouter.profileSetup;
    } else {
      _initialRoute = AppRouter.home;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache the logo image so it's ready before first paint
    precacheImage(const AssetImage("assets/images/logo.png"), context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CivicSight AI',
      theme: ThemeData(
        fontFamily: 'sans-serif',
        // Optimize page transitions globally
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      // Route based on auth state and profile completeness
      initialRoute: _initialRoute,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
