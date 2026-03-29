import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Services/auth_service.dart';
import '../Models/user_model.dart';
import '../Utils/app_router.dart';
import '../constants/colors.dart';
import 'reporting_screen.dart';
import 'map_screen.dart';
import 'my_reports_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  final List<Widget> _screens = const [
    MapScreen(),
    ReportingScreen(),
    MyReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navTheme = Theme.of(context).bottomNavigationBarTheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.fullName ?? 'User',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkText2
                                : AppColors.darkText,
                          ),
                        ),
                        if (user != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: user.role == UserRole.worker
                                  ? AppColors.primaryBlue
                                  : AppColors.primaryOrange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.role == UserRole.worker
                                  ? '🔧 Field Worker'
                                  : '👤 Citizen',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _showLogoutDialog(context),
                      icon: Icon(
                        Icons.logout_rounded,
                        color: isDark
                            ? AppColors.darkText2
                            : AppColors.primaryBlue,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),

              // Content with animated crossfade
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppColors.animNormal,
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    final offsetX =
                        _currentIndex >= _previousIndex ? 1.0 : -1.0;
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(offsetX * 0.06, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentIndex),
                    child: _screens[_currentIndex],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            HapticFeedback.selectionClick();
            setState(() {
              _previousIndex = _currentIndex;
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: navTheme.backgroundColor,
          selectedItemColor: navTheme.selectedItemColor,
          unselectedItemColor: navTheme.unselectedItemColor,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Maps',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_a_photo_outlined),
              activeIcon: Icon(Icons.add_a_photo),
              label: 'Report',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radius)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        title: Text('Logout',
            style: TextStyle(
                color: isDark ? AppColors.darkText2 : AppColors.darkText)),
        content: Text('Are you sure you want to logout?',
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    color: isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
              ),
            ),
            onPressed: () async {
              await AuthService().logout();
              HapticFeedback.mediumImpact();
              if (context.mounted) {
                Navigator.pop(context);
                AppRouter.navigateAndClearAll(context, AppRouter.login);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
