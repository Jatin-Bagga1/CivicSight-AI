import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'Services/auth_service.dart';
import 'Services/theme_provider.dart';
import 'Services/map_settings_provider.dart';
import 'Services/accent_color_provider.dart';
import 'Utils/app_router.dart';
import 'constants/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: "assets/.env");

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://lcyryfzfiduslebpffje.supabase.co', 
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxjeXJ5ZnpmaWR1c2xlYnBmZmplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1MzQ1NTYsImV4cCI6MjA4NzExMDU1Nn0.-xfC_wtwXYRdc4MCBb6VfSjos2pPiE_xo31YCF1_vqg',
  );

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
        ChangeNotifierProvider(create: (_) => AccentColorProvider()),
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
