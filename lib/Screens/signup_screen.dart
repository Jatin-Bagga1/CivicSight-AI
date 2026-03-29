import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../ViewModels/signup_view_model.dart';
import '../Models/user_model.dart';
import '../Utils/app_router.dart';
import '../constants/colors.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignUpViewModel(),
      child: const _SignUpScreenContent(),
    );
  }
}

class _SignUpScreenContent extends StatefulWidget {
  const _SignUpScreenContent();

  @override
  State<_SignUpScreenContent> createState() => _SignUpScreenContentState();
}

class _SignUpScreenContentState extends State<_SignUpScreenContent>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _handleSignUp(SignUpViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      if (viewModel.selectedRole == null) {
        _showSnackBar('Please select your role', isError: true);
        HapticFeedback.heavyImpact();
        return;
      }

      final success = await viewModel.signUp();
      if (success) {
        _showSnackBar('Account created successfully!');
        if (mounted) {
          final destination = viewModel.selectedRole == UserRole.worker
              ? AppRouter.workerDashboard
              : AppRouter.home;
          AppRouter.navigateAndReplace(context, destination);
        }
      } else if (viewModel.errorMessage != null) {
        _showSnackBar(viewModel.errorMessage!, isError: true);
        HapticFeedback.heavyImpact();
      }
    }
  }

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SignUpViewModel>();
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
              top: 60,
              left: -70,
              child: _GlowCircle(
                radius: 120,
                color:
                    AppColors.primaryOrange.withOpacity(isDark ? 0.12 : 0.18),
              ),
            ),
            Positioned(
              bottom: 80,
              right: -60,
              child: _GlowCircle(
                radius: 100,
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
                            const SizedBox(height: 12),

                            // Back button
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => AppRouter.goBack(context),
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  color: isDark
                                      ? AppColors.darkText2
                                      : AppColors.darkText,
                                ),
                              ),
                            ),

                            Image.asset("assets/images/logo.png", width: 170),
                            const SizedBox(height: 16),
                            Text(
                              "Create Account",
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
                              "Join Civic Sight AI today",
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Error message
                            Selector<SignUpViewModel, String?>(
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
                            Selector<SignUpViewModel, UserRole?>(
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
                                            "I am signing up as:",
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
                                        onChanged: viewModel.setName,
                                        validator: (value) {
                                          if (value == null ||
                                              value.isEmpty) {
                                            return 'Please enter your name';
                                          }
                                          if (value.length < 2) {
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
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        onChanged: viewModel.setEmail,
                                        validator: (value) {
                                          if (value == null ||
                                              value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          if (!_emailRegex
                                              .hasMatch(value)) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          prefixIcon: Icon(
                                              Icons.email_outlined,
                                              color: isDark
                                                  ? AppColors.primaryOrange
                                                  : AppColors.primaryBlue),
                                          hintText: "Email",
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
                                      const SizedBox(height: 14),

                                      // Password
                                      Selector<SignUpViewModel, bool>(
                                        selector: (_, vm) =>
                                            vm.isPasswordVisible,
                                        builder:
                                            (_, isPasswordVisible, __) {
                                          return TextFormField(
                                            controller:
                                                _passwordController,
                                            obscureText:
                                                !isPasswordVisible,
                                            onChanged:
                                                viewModel.setPassword,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter your password';
                                              }
                                              if (value.length < 6) {
                                                return 'Password must be at least 6 characters';
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              prefixIcon: Icon(
                                                  Icons.lock_outline,
                                                  color: isDark
                                                      ? AppColors
                                                          .primaryOrange
                                                      : AppColors
                                                          .primaryBlue),
                                              hintText: "Password",
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  isPasswordVisible
                                                      ? Icons.visibility
                                                      : Icons
                                                          .visibility_off,
                                                  color: isDark
                                                      ? Colors
                                                          .grey.shade500
                                                      : Colors.grey,
                                                ),
                                                onPressed: viewModel
                                                    .togglePasswordVisibility,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 14),

                                      // Confirm password
                                      Selector<SignUpViewModel, bool>(
                                        selector: (_, vm) =>
                                            vm.isConfirmPasswordVisible,
                                        builder: (_,
                                            isConfirmPasswordVisible,
                                            __) {
                                          return TextFormField(
                                            controller:
                                                _confirmPasswordController,
                                            obscureText:
                                                !isConfirmPasswordVisible,
                                            onChanged: viewModel
                                                .setConfirmPassword,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please confirm your password';
                                              }
                                              if (value !=
                                                  _passwordController
                                                      .text) {
                                                return 'Passwords do not match';
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              prefixIcon: Icon(
                                                  Icons.lock_outline,
                                                  color: isDark
                                                      ? AppColors
                                                          .primaryOrange
                                                      : AppColors
                                                          .primaryBlue),
                                              hintText: "Confirm Password",
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  isConfirmPasswordVisible
                                                      ? Icons.visibility
                                                      : Icons
                                                          .visibility_off,
                                                  color: isDark
                                                      ? Colors
                                                          .grey.shade500
                                                      : Colors.grey,
                                                ),
                                                onPressed: viewModel
                                                    .toggleConfirmPasswordVisibility,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Buttons section
                            Selector<SignUpViewModel, bool>(
                              selector: (_, vm) => vm.isLoading,
                              builder: (_, isLoading, __) {
                                return Column(
                                  children: [
                                    _GradientButton(
                                      label: "Create Account",
                                      isLoading: isLoading,
                                      onPressed: () =>
                                          _handleSignUp(viewModel),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: isDark
                                                ? Colors.white24
                                                : Colors.grey.shade400,
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 14),
                                          child: Text(
                                            "OR",
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: isDark
                                                ? Colors.white24
                                                : Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    _SocialButton(
                                      icon: Icons.g_mobiledata,
                                      label: "Continue with Google",
                                      isDark: isDark,
                                      onPressed: isLoading
                                          ? null
                                          : () => _showSnackBar(
                                              'Google Sign-Up coming soon!',
                                              isError: true),
                                    ),
                                    const SizedBox(height: 10),
                                    _SocialButton(
                                      icon: Icons.facebook,
                                      label: "Continue with Facebook",
                                      isDark: isDark,
                                      onPressed: isLoading
                                          ? null
                                          : () => _showSnackBar(
                                              'Facebook Sign-Up coming soon!',
                                              isError: true),
                                    ),
                                    const SizedBox(height: 28),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Already have an account? ",
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: isLoading
                                              ? null
                                              : () => AppRouter.goBack(
                                                  context),
                                          child: Text(
                                            "Log In",
                                            style: TextStyle(
                                              color: isDark
                                                  ? AppColors.primaryOrange
                                                  : AppColors.primaryBlue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              },
                            ),
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
              : (isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50),
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

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onPressed;
  const _SocialButton(
      {required this.icon,
      required this.label,
      required this.isDark,
      this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor:
              isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          side: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isDark ? Colors.white70 : Colors.blueGrey, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
