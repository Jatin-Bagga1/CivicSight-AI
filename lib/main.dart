import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'Services/auth_service.dart';
import 'Services/theme_provider.dart';
import 'Services/map_settings_provider.dart';
import 'Utils/app_router.dart';
import 'constants/app_theme.dart';

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
    precacheImage(const AssetImage("assets/images/logo.png"), context);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MapSettingsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'CivicSight AI',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.effectiveThemeMode,
            initialRoute: _initialRoute,
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
