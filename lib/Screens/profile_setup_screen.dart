import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../ViewModels/profile_setup_view_model.dart';
import '../Models/user_model.dart';
import '../Utils/app_router.dart';
import '../constants/colors.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileSetupViewModel(),
      child: const _ProfileSetupContent(),
    );
  }
}

class _ProfileSetupContent extends StatefulWidget {
  const _ProfileSetupContent();

  @override
  State<_ProfileSetupContent> createState() => _ProfileSetupContentState();
}

class _ProfileSetupContentState extends State<_ProfileSetupContent>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ProfileSetupViewModel>();
      _nameController.text = viewModel.fullName;
      _phoneController.text = viewModel.phone;
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSm)),
      ),
    );
  }

  Future<void> _handleSaveProfile(ProfileSetupViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      if (viewModel.selectedRole == null) {
        _showSnackBar('Please select your role', isError: true);
        HapticFeedback.heavyImpact();
        return;
      }

      final success = await viewModel.saveProfile();
      if (success) {
        _showSnackBar('Profile saved successfully!');
        if (mounted) {
          final destination = viewModel.selectedRole == UserRole.worker
              ? AppRouter.workerDashboard
              : AppRouter.home;
          AppRouter.navigateAndClearAll(context, destination);
        }
      } else if (viewModel.errorMessage != null) {
        _showSnackBar(viewModel.errorMessage!, isError: true);
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ProfileSetupViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 40,
              right: -70,
              child: _GlowCircle(
                radius: 130,
                color:
                    AppColors.primaryOrange.withOpacity(isDark ? 0.12 : 0.18),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: _GlowCircle(
                radius: 90,
                color:
                    AppColors.primaryBlue.withOpacity(isDark ? 0.12 : 0.15),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 32),

                            // Icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.primaryOrange
                                        : AppColors.primaryBlue)
                                    .withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 56,
                                color: isDark
                                    ? AppColors.primaryOrange
                                    : AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 20),

                            Text(
                              "Complete Your Profile",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.darkText2
                                    : AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "We need a few more details to get you started",
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            // Email badge
                            Selector<ProfileSetupViewModel, String?>(
                              selector: (_, vm) => vm.currentUser?.email,
                              builder: (_, email, __) {
                                if (email == null) {
                                  return const SizedBox.shrink();
                                }
                                return Container(
                                  margin: const EdgeInsets.only(top: 14),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white12
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.email_outlined,
                                          size: 18,
                                          color: isDark
                                              ? AppColors.primaryOrange
                                              : AppColors.primaryBlue),
                                      const SizedBox(width: 8),
                                      Text(
                                        email,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? AppColors.darkText2
                                              : AppColors.darkText,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Error message
                            Selector<ProfileSetupViewModel, String?>(
                              selector: (_, vm) => vm.errorMessage,
                              builder: (_, errorMessage, __) {
                                if (errorMessage == null) {
                                  return const SizedBox.shrink();
                                }
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppColors.radiusSm),
                                    border: Border.all(
                                        color:
                                            AppColors.error.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: AppColors.error, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(errorMessage,
                                            style: const TextStyle(
                                                color: AppColors.error,
                                                fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // Role selection glass card
                            Selector<ProfileSetupViewModel, UserRole?>(
                              selector: (_, vm) => vm.selectedRole,
                              builder: (_, selectedRole, __) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      AppColors.radiusXl),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 16, sigmaY: 16),
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: AppColors.glass(isDark),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "I am a:",
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.darkText2
                                                  : AppColors.darkText,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _RoleCard(
                                                  role: UserRole.citizen,
                                                  icon: Icons.person_outline,
                                                  title: "Citizen",
                                                  subtitle: "Report issues",
                                                  isSelected: selectedRole ==
                                                      UserRole.citizen,
                                                  isDark: isDark,
                                                  onTap: () => viewModel
                                                      .setRole(
                                                          UserRole.citizen),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _RoleCard(
                                                  role: UserRole.worker,
                                                  icon: Icons
                                                      .engineering_outlined,
                                                  title: "Field Worker",
                                                  subtitle: "Resolve issues",
                                                  isSelected: selectedRole ==
                                                      UserRole.worker,
                                                  isDark: isDark,
                                                  onTap: () => viewModel
                                                      .setRole(
                                                          UserRole.worker),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Input fields glass card
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusXl),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: AppColors.glass(isDark),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _nameController,
                                        onChanged: viewModel.setFullName,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Please enter your full name';
                                          }
                                          if (value.trim().length < 2) {
                                            return 'Name must be at least 2 characters';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          prefixIcon: Icon(
                                              Icons.person_outline,
                                              color: isDark
                                                  ? AppColors.primaryOrange
                                                  : AppColors.primaryBlue),
                                          hintText: "Full Name",
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        onChanged: viewModel.setPhone,
                                        validator: (value) {
                                          if (value != null &&
                                              value.isNotEmpty) {
                                            if (value.length < 7) {
                                              return 'Please enter a valid phone number';
                                            }
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          prefixIcon: Icon(
                                              Icons.phone_outlined,
                                              color: isDark
                                                  ? AppColors.primaryOrange
                                                  : AppColors.primaryBlue),
                                          hintText: "Phone Number (optional)",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Save button
                            Selector<ProfileSetupViewModel, bool>(
                              selector: (_, vm) => vm.isLoading,
                              builder: (_, isLoading, __) {
                                return _GradientButton(
                                  label: "Continue",
                                  isLoading: isLoading,
                                  onPressed: () =>
                                      _handleSaveProfile(viewModel),
                                );
                              },
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared UI widgets ───

class _GlowCircle extends StatelessWidget {
  final double radius;
  final Color color;
  const _GlowCircle({required this.radius, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = role == UserRole.worker
        ? AppColors.primaryBlue
        : AppColors.primaryOrange;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppColors.animFast,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withOpacity(isDark ? 0.15 : 0.1)
              : (isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          border: Border.all(
            color: isSelected
                ? accent
                : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 36,
                color: isSelected
                    ? accent
                    : (isDark ? Colors.white38 : Colors.grey.shade400)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? (isDark ? AppColors.darkText2 : AppColors.darkText)
                    : (isDark ? Colors.white54 : Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Icon(Icons.check_circle, color: accent, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  const _GradientButton(
      {required this.label,
      required this.isLoading,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.radius),
        gradient: AppColors.buttonGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radius),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
