import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../Services/auth_service.dart';
import '../Services/theme_provider.dart';
import '../Services/map_settings_provider.dart';
import '../Models/user_model.dart';
import '../Utils/app_router.dart';
import '../constants/colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Profile Card ───
          _ProfileCard(user: user, isDark: isDark),
          const SizedBox(height: 20),

          // ─── Appearance ───
          _SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
          const _ThemeSelector(),
          const SizedBox(height: 20),

          // ─── Notifications ───
          _SectionHeader(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
          ),
          _SettingsCard(
            children: [
              _ToggleTile(
                icon: Icons.campaign_outlined,
                title: 'Report Status Updates',
                subtitle: 'Get notified when your report status changes',
                prefKey: 'notif_report_updates',
                defaultValue: true,
              ),
              const Divider(height: 1),
              _ToggleTile(
                icon: Icons.email_outlined,
                title: 'Email Alerts',
                subtitle: 'Receive email notifications',
                prefKey: 'notif_email_alerts',
                defaultValue: false,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Map Settings ───
          _SectionHeader(title: 'Map', icon: Icons.map_outlined),
          _SettingsCard(
            children: [
              const _MapTypeSelector(),
              const Divider(height: 1),
              Consumer<MapSettingsProvider>(
                builder: (context, mapSettings, _) {
                  return SwitchListTile(
                    secondary: const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.primaryBlue,
                    ),
                    title: const Text(
                      'Show Resolved Reports',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      'Display resolved issues on the map',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    value: mapSettings.showResolved,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      mapSettings.setShowResolved(val);
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Privacy ───
          _SectionHeader(title: 'Privacy', icon: Icons.shield_outlined),
          _SettingsCard(
            children: [
              _ToggleTile(
                icon: Icons.visibility_off_outlined,
                title: 'Anonymous Reporting',
                subtitle: 'Hide your identity on submitted reports',
                prefKey: 'privacy_anonymous',
                defaultValue: false,
              ),
              const Divider(height: 1),
              _ToggleTile(
                icon: Icons.analytics_outlined,
                title: 'Usage Analytics',
                subtitle: 'Help improve the app with anonymous data',
                prefKey: 'privacy_analytics',
                defaultValue: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Help & Support ───
          _SectionHeader(title: 'Help & Support', icon: Icons.help_outline),
          _SettingsCard(
            children: [
              _NavTile(
                icon: Icons.question_answer_outlined,
                title: 'FAQ',
                onTap: () => _showComingSoon(context, 'FAQ'),
              ),
              const Divider(height: 1),
              _NavTile(
                icon: Icons.support_agent_outlined,
                title: 'Contact Support',
                onTap: () => _showComingSoon(context, 'Contact Support'),
              ),
              const Divider(height: 1),
              _NavTile(
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug',
                onTap: () => _showComingSoon(context, 'Report a Bug'),
              ),
              const Divider(height: 1),
              _NavTile(
                icon: Icons.star_outline,
                title: 'Rate the App',
                onTap: () => _showComingSoon(context, 'Rate the App'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── About ───
          _SectionHeader(title: 'About', icon: Icons.info_outline),
          _SettingsCard(
            children: [
              _NavTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () => _showComingSoon(context, 'Terms of Service'),
              ),
              const Divider(height: 1),
              _NavTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => _showComingSoon(context, 'Privacy Policy'),
              ),
              const Divider(height: 1),
              _NavTile(
                icon: Icons.code_outlined,
                title: 'Open Source Licenses',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'CivicSight AI',
                  applicationVersion: '1.0.0',
                ),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.info_outline, color: AppColors.primaryBlue),
                title: Text('Version'),
                trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Account ───
          _SectionHeader(
            title: 'Account',
            icon: Icons.manage_accounts_outlined,
          ),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.primaryBlue),
                title: const Text('Logout'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showLogoutDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(color: AppColors.error),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.error,
                ),
                onTap: () => _showDeleteDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  static void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — Coming soon!'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  static void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await AuthService().logout();
              HapticFeedback.mediumImpact();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                AppRouter.navigateAndClearAll(ctx, AppRouter.login);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Delete Account'),
        content: const Text(
          'This action is permanent and cannot be undone. All your data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showComingSoon(ctx, 'Account deletion');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Card ───

class _ProfileCard extends StatelessWidget {
  final UserModel? user;
  final bool isDark;

  const _ProfileCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final initials = (user?.fullName ?? 'U')
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .take(2)
        .join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText2 : AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                if (user != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: user!.role == UserRole.worker
                          ? AppColors.primaryBlue
                          : AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user!.role == UserRole.worker
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
              ],
            ),
          ),
          // Edit
          IconButton(
            onPressed: () =>
                SettingsScreen._showComingSoon(context, 'Edit Profile'),
            icon: Icon(
              Icons.edit_outlined,
              color: isDark ? Colors.grey.shade400 : AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryOrange),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Card (grouped container) ───

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(children: children),
      ),
    );
  }
}

// ─── Theme Selector ───

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _ThemeChip(
            label: 'Light',
            icon: Icons.light_mode,
            isSelected: provider.themeMode == 'light',
            onTap: () {
              HapticFeedback.selectionClick();
              provider.setThemeMode('light');
            },
          ),
          const SizedBox(width: 8),
          _ThemeChip(
            label: 'Dark',
            icon: Icons.dark_mode,
            isSelected: provider.themeMode == 'dark',
            onTap: () {
              HapticFeedback.selectionClick();
              provider.setThemeMode('dark');
            },
          ),
          const SizedBox(width: 8),
          _ThemeChip(
            label: 'Auto',
            icon: Icons.brightness_auto,
            isSelected: provider.themeMode == 'auto',
            onTap: () {
              HapticFeedback.selectionClick();
              provider.setThemeMode('auto');
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryBlue
                  : Colors.grey.withOpacity(0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.primaryBlue : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primaryBlue : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Toggle Tile ───

class _ToggleTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String prefKey;
  final bool defaultValue;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.prefKey,
    required this.defaultValue,
  });

  @override
  State<_ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<_ToggleTile> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.defaultValue;
    _load();
  }

  Future<void> _load() async {
    // SharedPreferences would be loaded here for persistence
    // For now, use defaultValue
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(widget.icon, color: AppColors.primaryBlue),
      title: Text(widget.title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        widget.subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      value: _value,
      onChanged: (val) {
        HapticFeedback.selectionClick();
        setState(() => _value = val);
      },
    );
  }
}

// ─── Nav Tile ───

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}

// ─── Map Type Selector ───

class _MapTypeSelector extends StatelessWidget {
  const _MapTypeSelector();

  @override
  Widget build(BuildContext context) {
    final mapSettings = context.watch<MapSettingsProvider>();

    return ListTile(
      leading: const Icon(Icons.layers_outlined, color: AppColors.primaryBlue),
      title: const Text('Map Type', style: TextStyle(fontSize: 14)),
      trailing: DropdownButton<String>(
        value: mapSettings.mapTypeLabel,
        underline: const SizedBox(),
        items: ['Normal', 'Satellite', 'Terrain'].map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            HapticFeedback.selectionClick();
            mapSettings.setMapType(val);
          }
        },
      ),
    );
  }
}
