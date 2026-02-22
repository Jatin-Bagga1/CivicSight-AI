import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Screens/login_screen.dart';
import '../Screens/signup_screen.dart';
// import '../Screens/auth/forgot_password_screen.dart'; // File missing
import '../Screens/profile_setup_screen.dart';
import '../Screens/home_screen.dart';
import '../Screens/map_screen.dart';
import '../Screens/dashboard_screen.dart';
import '../Screens/citizen_profile_screen.dart';

class AppRouter {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String map = '/map';
  static const String dashboard = '/dashboard';
  static const String citizenProfile = '/citizen-profile';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case forgotPassword:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Forgot Password')),
            body: const Center(child: Text('Feature coming soon')),
          ),
        );
      case profileSetup:
        return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());
      case home:
        // Redirect home to dashboard
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case map:
        return MaterialPageRoute(builder: (_) => const MapScreen());
      case citizenProfile:
        return MaterialPageRoute(builder: (_) => const CitizenProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  /// Navigate to a route
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    HapticFeedback.lightImpact();
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  /// Navigate and replace the current route
  static Future<void> navigateAndReplace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    HapticFeedback.lightImpact();
    await Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and remove all previous routes
  static Future<void> navigateAndClearAll(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    HapticFeedback.mediumImpact();
    await Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Go back
  static void goBack<T>(BuildContext context, [T? result]) {
    HapticFeedback.selectionClick();
    Navigator.pop(context, result);
  }
}
