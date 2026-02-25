import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../ViewModels/citizen_profile_view_model.dart';
import '../Services/accent_color_provider.dart';
import '../constants/colors.dart';

class CitizenProfileScreen extends StatelessWidget {
  const CitizenProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = CitizenProfileViewModel();
        // Attach the app-level accent provider so colour changes propagate
        vm.attachAccentProvider(context.read<AccentColorProvider>());
        vm.load();
        return vm;
      },
      child: const _CitizenProfileBody(),
    );
  }
}

class _CitizenProfileBody extends StatelessWidget {
  const _CitizenProfileBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CitizenProfileViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg1 : AppColors.lightBg1,
      appBar: AppBar(
        title: const Text('Citizen Profile'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkText2 : AppColors.darkText,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.errorMessage != null && vm.profile == null
              ? _ErrorView(message: vm.errorMessage!)
              : _ProfileForm(isDark: isDark),
    );
  }
}

// ─── Error Fallback ───

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<CitizenProfileViewModel>().load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main Form ───

class _ProfileForm extends StatelessWidget {
  final bool isDark;
  const _ProfileForm({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CitizenProfileViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Accent Colour Picker ───
          _SectionLabel(label: 'Accent Colour', isDark: isDark),
          const SizedBox(height: 8),
          _ColorPickerRow(isDark: isDark),
          const SizedBox(height: 24),

          // ─── Editable Fields ───
          _SectionLabel(label: 'Address Information', isDark: isDark),
          const SizedBox(height: 8),
          _StyledField(
            controller: vm.addressCtrl,
            label: 'Address',
            icon: Icons.home_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _StyledField(
            controller: vm.cityCtrl,
            label: 'City',
            icon: Icons.location_city_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _StyledField(
            controller: vm.provinceCtrl,
            label: 'Province',
            icon: Icons.map_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _StyledField(
            controller: vm.zipCodeCtrl,
            label: 'Zip Code',
            icon: Icons.markunread_mailbox_outlined,
            isDark: isDark,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          // ─── Timestamps ───
          _SectionLabel(label: 'Profile Info', isDark: isDark),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.numbers,
            label: 'Total Reports',
            value: '${vm.profile?.totalReports ?? 0}',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.calendar_today_outlined,
            label: 'Created',
            value: _formatTimestamp(vm.profile?.createdAt),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.update_outlined,
            label: 'Last Updated',
            value: _formatTimestamp(vm.profile?.updatedAt),
            isDark: isDark,
          ),
          const SizedBox(height: 32),

          // ─── Save Button ───
          _SaveButton(isDark: isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    final month = _monthName(local.month);
    return '$month ${local.day}, ${local.year}  ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[m - 1];
  }
}

// ─── Section Label ───

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: AppColors.primaryOrange),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

// ─── Styled Text Field ───

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final TextInputType keyboardType;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDark ? AppColors.darkText2 : AppColors.darkText,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 20),
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.grey.shade700
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// ─── Read-only Info Tile ───

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryOrange),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText2 : AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Colour Picker Row ───

class _ColorPickerRow extends StatefulWidget {
  final bool isDark;
  const _ColorPickerRow({required this.isDark});

  @override
  State<_ColorPickerRow> createState() => _ColorPickerRowState();
}

class _ColorPickerRowState extends State<_ColorPickerRow> {
  static const List<int> _paletteHex = [
    0xFF1A4D94, // primaryBlue
    0xFFF28C38, // primaryOrange
    0xFF4CAF50, // green
    0xFFE53935, // red
    0xFF9C27B0, // purple
    0xFF00BCD4, // cyan
    0xFF795548, // brown
    0xFF607D8B, // blueGrey
  ];

  late int _selectedHex;

  @override
  void initState() {
    super.initState();
    _selectedHex = context.read<CitizenProfileViewModel>().accentColorHex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vmHex = context.read<CitizenProfileViewModel>().accentColorHex;
    if (_selectedHex != vmHex) {
      _selectedHex = vmHex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _paletteHex.map((hex) {
          final color = Color(hex);
          final selected = _selectedHex == hex;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedHex = hex);
              context.read<CitizenProfileViewModel>().setAccentColor(hex);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Save Button ───

class _SaveButton extends StatelessWidget {
  final bool isDark;
  const _SaveButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CitizenProfileViewModel>();

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: vm.saving ? null : () => _onSave(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: vm.saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Save Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _onSave(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final vm = context.read<CitizenProfileViewModel>();
    final success = await vm.save();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Profile saved successfully!'
              : vm.errorMessage ?? 'Failed to save profile.',
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );

    if (success) {
      Navigator.pop(context);
    }
  }
}
