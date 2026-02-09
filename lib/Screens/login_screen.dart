import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../ViewModels/login_view_model.dart';
import '../Utils/app_router.dart';

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

class _LoginScreenContentState extends State<_LoginScreenContent> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            AppRouter.navigateAndReplace(context, AppRouter.home);
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
          AppRouter.navigateAndReplace(context, AppRouter.home);
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
          AppRouter.navigateAndReplace(context, AppRouter.home);
        }
      }
    } else if (viewModel.errorMessage != null) {
      _showSnackBar(viewModel.errorMessage!, isError: true);
      HapticFeedback.heavyImpact();
    }
  }

  // Cached email regex for validation
  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<LoginViewModel>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD6E4F0), Color(0xFFF9D1B7)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative tech patterns — static, never rebuilds
            const Positioned(
              top: 100,
              right: -50,
              child: RepaintBoundary(
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo — static, outside Consumer
                        Image.asset(
                          "assets/images/logo.png",
                          width: 250,
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          "A Sight on Every Street",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A2B47),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Error Message — only rebuilds when errorMessage changes
                        Selector<LoginViewModel, String?>(
                          selector: (_, vm) => vm.errorMessage,
                          builder: (context, errorMessage, _) {
                            if (errorMessage == null) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      errorMessage,
                                      style: TextStyle(color: Colors.red.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Email Field — static, uses controller not ViewModel
                        _buildTextField(
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          hint: "Email",
                          keyboardType: TextInputType.emailAddress,
                          onChanged: viewModel.setEmail,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!_emailRegex.hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        // Password Field — only rebuilds when visibility changes
                        Selector<LoginViewModel, bool>(
                          selector: (_, vm) => vm.isPasswordVisible,
                          builder: (context, isPasswordVisible, _) {
                            return _buildTextField(
                              controller: _passwordController,
                              icon: Icons.lock_outline,
                              hint: "Password",
                              isPassword: true,
                              isPasswordVisible: isPasswordVisible,
                              onTogglePassword: viewModel.togglePasswordVisibility,
                              onChanged: viewModel.setPassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            );
                          },
                        ),

                        // Forgot Password — only needs isLoading
                        Selector<LoginViewModel, bool>(
                          selector: (_, vm) => vm.isLoading,
                          builder: (context, isLoading, _) {
                            return Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => _handleForgotPassword(viewModel),
                                    child: const Text(
                                      "Forgot Password?",
                                      style: TextStyle(color: Colors.blueGrey),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Primary Login Button
                                Container(
                                  width: double.infinity,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1A4D94), Color(0xFFF28C38)],
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x4D2196F3),
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      )
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    onPressed: isLoading
                                        ? null
                                        : () => _handleLogin(viewModel),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            "Log In",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 25),

                                // Divider with "OR"
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(color: Colors.grey.shade400),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        "OR",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(color: Colors.grey.shade400),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Social Buttons
                                _buildSocialButton(
                                  icon: Icons.g_mobiledata,
                                  text: "Continue with Google",
                                  onPressed: isLoading
                                      ? null
                                      : () => _handleGoogleLogin(viewModel),
                                ),
                                const SizedBox(height: 12),
                                _buildSocialButton(
                                  icon: Icons.facebook,
                                  text: "Continue with Facebook",
                                  onPressed: isLoading
                                      ? null
                                      : () => _handleFacebookLogin(viewModel),
                                ),

                                const SizedBox(height: 30),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Don't have an account? "),
                                    GestureDetector(
                                      onTap: isLoading
                                          ? null
                                          : () {
                                              AppRouter.navigateTo(context, AppRouter.signup);
                                            },
                                      child: const Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1A4D94)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

