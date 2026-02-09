import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../ViewModels/profile_setup_view_model.dart';
import '../Models/user_model.dart';
import '../Utils/app_router.dart';

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

class _ProfileSetupContentState extends State<_ProfileSetupContent> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers from existing data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ProfileSetupViewModel>();
      _nameController.text = viewModel.fullName;
      _phoneController.text = viewModel.phone;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
          AppRouter.navigateAndClearAll(context, AppRouter.home);
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
              top: 80,
              right: -60,
              child: RepaintBoundary(
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
            ),
            const Positioned(
              bottom: 120,
              left: -40,
              child: RepaintBoundary(
                child: CircleAvatar(
                  radius: 70,
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
                        const SizedBox(height: 40),

                        // Icon — static
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Color(0x1A1A4D94),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 60,
                            color: Color(0xFF1A4D94),
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          "Complete Your Profile",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A2B47),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "We need a few more details to get you started",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Show email badge — only rebuilds when currentUser changes
                        Selector<ProfileSetupViewModel, String?>(
                          selector: (_, vm) => vm.currentUser?.email,
                          builder: (context, email, _) {
                            if (email == null) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.email_outlined,
                                    size: 18,
                                    color: Color(0xFF1A4D94),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1A2B47),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        // Error Message — only rebuilds on errorMessage change
                        Selector<ProfileSetupViewModel, String?>(
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
                        Selector<ProfileSetupViewModel, UserRole?>(
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
                                    "I am a:",
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

                        // Full Name Field — static, uses controller
                        _buildTextField(
                          controller: _nameController,
                          icon: Icons.person_outline,
                          hint: "Full Name",
                          onChanged: viewModel.setFullName,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters';
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
                        const SizedBox(height: 30),

                        // Save Button — only rebuilds on loading change
                        Selector<ProfileSetupViewModel, bool>(
                          selector: (_, vm) => vm.isLoading,
                          builder: (context, isLoading, _) {
                            return Container(
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
                                  ),
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
                                    : () => _handleSaveProfile(viewModel),
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
                                        "Continue",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
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
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1A4D94)),
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
}
