import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Screens/login_screen.dart';
import '../Screens/signup_screen.dart';
import '../Screens/home_screen.dart';
import 'page_transitions.dart';

/// Centralized routing with custom transitions
class AppRouter {
  // Route names
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';

  /// Generate route with appropriate transition
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return PageTransitions.fadeThrough(page: const LoginScreen());
      
      case signup:
        return PageTransitions.slideRight(page: const SignUpScreen());
      
      case home:
        return PageTransitions.scale(page: const HomeScreen());
      
      default:
        return PageTransitions.fade(
          page: Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  /// Navigate with replacement (clears back stack)
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

  /// Navigate with push (adds to stack)
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    HapticFeedback.lightImpact();
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and clear all previous routes
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

  /// Go back with optional result
  static void goBack<T>(BuildContext context, [T? result]) {
    HapticFeedback.selectionClick();
    Navigator.pop(context, result);
  }

  /// Navigate with custom transition
  static Future<T?> navigateWithTransition<T>(
    BuildContext context,
    Widget page, {
    TransitionType type = TransitionType.slideRight,
  }) async {
    HapticFeedback.lightImpact();
    
    late Route<T> route;
    switch (type) {
      case TransitionType.fade:
        route = PageTransitions.fade<T>(page: page);
        break;
      case TransitionType.slideRight:
        route = PageTransitions.slideRight<T>(page: page);
        break;
      case TransitionType.slideLeft:
        route = PageTransitions.slideLeft<T>(page: page);
        break;
      case TransitionType.slideUp:
        route = PageTransitions.slideUp<T>(page: page);
        break;
      case TransitionType.scale:
        route = PageTransitions.scale<T>(page: page);
        break;
      case TransitionType.fadeThrough:
        route = PageTransitions.fadeThrough<T>(page: page);
        break;
    }
    
    return Navigator.push<T>(context, route);
  }

  /// Replace with custom transition
  static Future<T?> replaceWithTransition<T>(
    BuildContext context,
    Widget page, {
    TransitionType type = TransitionType.fadeThrough,
  }) async {
    HapticFeedback.lightImpact();
    
    late Route<T> route;
    switch (type) {
      case TransitionType.fade:
        route = PageTransitions.fade<T>(page: page);
        break;
      case TransitionType.slideRight:
        route = PageTransitions.slideRight<T>(page: page);
        break;
      case TransitionType.slideLeft:
        route = PageTransitions.slideLeft<T>(page: page);
        break;
      case TransitionType.slideUp:
        route = PageTransitions.slideUp<T>(page: page);
        break;
      case TransitionType.scale:
        route = PageTransitions.scale<T>(page: page);
        break;
      case TransitionType.fadeThrough:
        route = PageTransitions.fadeThrough<T>(page: page);
        break;
    }
    
    return Navigator.pushReplacement<T, T>(context, route);
  }
}

/// Transition types available
enum TransitionType {
  fade,
  slideRight,
  slideLeft,
  slideUp,
  scale,
  fadeThrough,
}
