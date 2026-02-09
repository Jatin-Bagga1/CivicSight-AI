import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../ViewModels/signup_view_model.dart';
import '../Models/user_model.dart';
import '../Utils/app_router.dart';

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

class _SignUpScreenContentState extends State<_SignUpScreenContent> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
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
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          AppRouter.navigateAndReplace(context, AppRouter.home);
        }
      } else if (viewModel.errorMessage != null) {
        _showSnackBar(viewModel.errorMessage!, isError: true);
        HapticFeedback.heavyImpact();
      }
    }
  }

  // Cached email regex for validation
  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SignUpViewModel>();

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
            // Decorative patterns — static, wrapped in RepaintBoundary
            const Positioned(
              top: 100,
              left: -50,
              child: RepaintBoundary(
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
            ),
            const Positioned(
              bottom: 100,
              right: -50,
              child: RepaintBoundary(
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Color(0x26FFFFFF),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Back Button — static
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => AppRouter.goBack(context),
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Color(0xFF1A2B47),
                            ),
                          ),
                        ),

                        // Logo — static
                        Image.asset(
                          "assets/images/logo.png",
                          width: 180,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A2B47),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Join Civic Sight AI today",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Error Message — only rebuilds on errorMessage change
                        Selector<SignUpViewModel, String?>(
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

                        // Role Selection — only rebuilds on role change
                        Selector<SignUpViewModel, UserRole?>(
                          selector: (_, vm) => vm.selectedRole,
                          builder: (context, selectedRole, _) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0D000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "I am signing up as:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A2B47),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildRoleCard(
                                          role: UserRole.citizen,
                                          icon: Icons.person_outline,
                                          title: "Citizen",
                                          subtitle: "Report issues",
                                          isSelected: selectedRole == UserRole.citizen,
                                          onTap: () => viewModel.setRole(UserRole.citizen),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildRoleCard(
                                          role: UserRole.worker,
                                          icon: Icons.engineering_outlined,
                                          title: "Field Worker",
                                          subtitle: "Resolve issues",
                                          isSelected: selectedRole == UserRole.worker,
                                          onTap: () => viewModel.setRole(UserRole.worker),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Name Field — static, uses controller
                        _buildTextField(
                          controller: _nameController,
                          icon: Icons.person_outline,
                          hint: "Full Name",
                          onChanged: viewModel.setName,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            if (value.length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        // Email Field — static, uses controller
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

                        // Phone Number Field — static, uses controller
                        _buildTextField(
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          hint: "Phone Number (optional)",
                          keyboardType: TextInputType.phone,
                          onChanged: viewModel.setPhone,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (value.length < 7) {
                                return 'Please enter a valid phone number';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        // Password Field — rebuilds only on visibility toggle
                        Selector<SignUpViewModel, bool>(
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
                        const SizedBox(height: 15),

                        // Confirm Password Field — rebuilds only on visibility toggle
                        Selector<SignUpViewModel, bool>(
                          selector: (_, vm) => vm.isConfirmPasswordVisible,
                          builder: (context, isConfirmPasswordVisible, _) {
                            return _buildTextField(
                              controller: _confirmPasswordController,
                              icon: Icons.lock_outline,
                              hint: "Confirm Password",
                              isPassword: true,
                              isPasswordVisible: isConfirmPasswordVisible,
                              onTogglePassword: viewModel.toggleConfirmPasswordVisibility,
                              onChanged: viewModel.setConfirmPassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 25),

                        // Loading-dependent section
                        Selector<SignUpViewModel, bool>(
                          selector: (_, vm) => vm.isLoading,
                          builder: (context, isLoading, _) {
                            return Column(
                              children: [
                                // Sign Up Button
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
                                        : () => _handleSignUp(viewModel),
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
                                            "Create Account",
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
                                  onPressed: isLoading ? null : () {
                                    _showSnackBar('Google Sign-Up coming soon!', isError: true);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildSocialButton(
                                  icon: Icons.facebook,
                                  text: "Continue with Facebook",
                                  onPressed: isLoading ? null : () {
                                    _showSnackBar('Facebook Sign-Up coming soon!', isError: true);
                                  },
                                ),

                                const SizedBox(height: 30),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Already have an account? "),
                                    GestureDetector(
                                      onTap: isLoading
                                          ? null
                                          : () => AppRouter.goBack(context),
                                      child: const Text(
                                        "Log In",
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
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

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (role == UserRole.worker 
                  ? const Color(0xFF1A4D94).withValues(alpha: 0.1) 
                  : const Color(0xFFF28C38).withValues(alpha: 0.1))
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? (role == UserRole.worker 
                    ? const Color(0xFF1A4D94) 
                    : const Color(0xFFF28C38))
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected 
                  ? (role == UserRole.worker 
                      ? const Color(0xFF1A4D94) 
                      : const Color(0xFFF28C38))
                  : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? const Color(0xFF1A2B47) 
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.check_circle,
                  color: role == UserRole.worker 
                      ? const Color(0xFF1A4D94) 
                      : const Color(0xFFF28C38),
                  size: 20,
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
