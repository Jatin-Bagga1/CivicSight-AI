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

class CivicSightApp extends StatelessWidget {
  const CivicSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in to determine initial route
    final bool isLoggedIn = AuthService().isLoggedIn;

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
      // Route to home if logged in, otherwise to login
      initialRoute: isLoggedIn ? AppRouter.home : AppRouter.login,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
