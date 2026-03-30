import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../ViewModels/login_view_model.dart';
import '../Utils/app_router.dart';
import '../constants/colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: const _LoginScreenContent(),
    );
  }
}

class _LoginScreenContent extends StatefulWidget {
  const _LoginScreenContent();

  @override
  State<_LoginScreenContent> createState() => _LoginScreenContentState();
}

class _LoginScreenContentState extends State<_LoginScreenContent>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleLogin(LoginViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await viewModel.login();
      if (success) {
        _showSnackBar('Login successful! Welcome ${viewModel.user?.fullName}');
        if (mounted) {
          if (viewModel.needsProfileSetup) {
            AppRouter.navigateAndReplace(context, AppRouter.profileSetup);
          } else {
            if (viewModel.user?.role.name == 'worker') {
              AppRouter.navigateAndReplace(context, AppRouter.workerDashboard);
            } else {
              AppRouter.navigateAndReplace(context, AppRouter.home);
            }
          }
        }
      } else if (viewModel.errorMessage != null) {
        _showSnackBar(viewModel.errorMessage!, isError: true);
        HapticFeedback.heavyImpact();
      }
    }
  }

  Future<void> _handleForgotPassword(LoginViewModel viewModel) async {
    if (_emailController.text.isEmpty) {
      _showSnackBar('Please enter your email address first', isError: true);
      return;
    }
    final success = await viewModel.forgotPassword();
    if (success) {
      _showSnackBar('Password reset email sent! Check your inbox.');
    } else if (viewModel.errorMessage != null) {
      _showSnackBar(viewModel.errorMessage!, isError: true);
    }
  }

  Future<void> _handleGoogleLogin(LoginViewModel viewModel) async {
    final success = await viewModel.loginWithGoogle();
    if (success) {
      _showSnackBar('Google login successful!');
      if (mounted) {
        if (viewModel.needsProfileSetup) {
          AppRouter.navigateAndReplace(context, AppRouter.profileSetup);
        } else {
          if (viewModel.user?.role.name == 'worker') {
            AppRouter.navigateAndReplace(context, AppRouter.workerDashboard);
          } else {
            AppRouter.navigateAndReplace(context, AppRouter.home);
          }
        }
      }
    } else if (viewModel.errorMessage != null) {
      _showSnackBar(viewModel.errorMessage!, isError: true);
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _handleFacebookLogin(LoginViewModel viewModel) async {
    final success = await viewModel.loginWithFacebook();
    if (success) {
      _showSnackBar('Facebook login successful!');
      if (mounted) {
        if (viewModel.needsProfileSetup) {
          AppRouter.navigateAndReplace(context, AppRouter.profileSetup);
        } else {
          if (viewModel.user?.role.name == 'worker') {
            AppRouter.navigateAndReplace(context, AppRouter.workerDashboard);
          } else {
            AppRouter.navigateAndReplace(context, AppRouter.home);
          }
        }
      }
    } else if (viewModel.errorMessage != null) {
      _showSnackBar(viewModel.errorMessage!, isError: true);
      HapticFeedback.heavyImpact();
    }
  }

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<LoginViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: Stack(
          children: [
            // Decorative blurred circles
            Positioned(
              top: -60,
              right: -60,
              child: _GlowCircle(
                radius: 140,
                color: AppColors.primaryOrange.withOpacity(isDark ? 0.15 : 0.2),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: _GlowCircle(
                radius: 160,
                color: AppColors.primaryBlue.withOpacity(isDark ? 0.15 : 0.18),
              ),
            ),
            Center(
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
                            const SizedBox(height: 40),
                            Image.asset("assets/images/logo.png", width: 220),
                            const SizedBox(height: 32),
                            Text(
                              "A Sight on Every Street",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.darkText2
                                    : AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Glass card wrapping inputs
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
                                      // Error
                                      Selector<LoginViewModel, String?>(
                                        selector: (_, vm) => vm.errorMessage,
                                        builder: (_, errorMessage, __) {
                                          if (errorMessage == null) {
                                            return const SizedBox.shrink();
                                          }
                                          return Container(
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(
                                                bottom: 16),
                                            decoration: BoxDecoration(
                                              color: AppColors.error
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppColors.radiusSm),
                                              border: Border.all(
                                                color: AppColors.error
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                    Icons.error_outline,
                                                    color: AppColors.error,
                                                    size: 20),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    errorMessage,
                                                    style: const TextStyle(
                                                        color: AppColors.error,
                                                        fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),

                                      // Email
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
                                          if (!_emailRegex.hasMatch(value)) {
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

                                      // Password
                                      Selector<LoginViewModel, bool>(
                                        selector: (_, vm) =>
                                            vm.isPasswordVisible,
                                        builder:
                                            (_, isPasswordVisible, __) {
                                          return TextFormField(
                                            controller: _passwordController,
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

                                      // Forgot password
                                      Selector<LoginViewModel, bool>(
                                        selector: (_, vm) => vm.isLoading,
                                        builder: (_, isLoading, __) {
                                          return Align(
                                            alignment:
                                                Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: isLoading
                                                  ? null
                                                  : () =>
                                                      _handleForgotPassword(
                                                          viewModel),
                                              child: Text(
                                                "Forgot Password?",
                                                style: TextStyle(
                                                  color: isDark
                                                      ? AppColors
                                                          .primaryOrange
                                                          .withOpacity(
                                                              0.8)
                                                      : AppColors
                                                          .primaryBlue
                                                          .withOpacity(
                                                              0.7),
                                                  fontSize: 13,
                                                ),
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

                            // Login & social section
                            Selector<LoginViewModel, bool>(
                              selector: (_, vm) => vm.isLoading,
                              builder: (_, isLoading, __) {
                                return Column(
                                  children: [
                                    _GradientButton(
                                      label: "Log In",
                                      isLoading: isLoading,
                                      onPressed: () =>
                                          _handleLogin(viewModel),
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
                                          : () => _handleGoogleLogin(
                                              viewModel),
                                    ),
                                    const SizedBox(height: 10),
                                    _SocialButton(
                                      icon: Icons.facebook,
                                      label: "Continue with Facebook",
                                      isDark: isDark,
                                      onPressed: isLoading
                                          ? null
                                          : () => _handleFacebookLogin(
                                              viewModel),
                                    ),
                                    const SizedBox(height: 28),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account? ",
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: isLoading
                                              ? null
                                              : () => AppRouter.navigateTo(
                                                  context,
                                                  AppRouter.signup),
                                          child: Text(
                                            "Sign Up",
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
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
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

