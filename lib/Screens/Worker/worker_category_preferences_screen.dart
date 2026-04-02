import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../ViewModels/worker_category_preferences_view_model.dart';
import '../../constants/colors.dart';

class WorkerCategoryPreferencesScreen extends StatelessWidget {
  const WorkerCategoryPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorkerCategoryPreferencesViewModel(),
      child: const _PreferencesContent(),
    );
  }
}

class _PreferencesContent extends StatelessWidget {
  const _PreferencesContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkerCategoryPreferencesViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                      color: isDark ? AppColors.darkText2 : AppColors.darkText,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Category Preferences',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? AppColors.darkText2 : AppColors.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Description ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Select the categories you prefer to work on. '
                  'These preferences help assign the most relevant tasks to you.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Select All / Deselect All Row ──
              if (!vm.isLoading && vm.allCategories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        '${vm.selectedCategoryIds.length} of ${vm.allCategories.length} selected',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: vm.allSelected ? vm.deselectAll : vm.selectAll,
                        child: Text(
                          vm.allSelected ? 'Deselect All' : 'Select All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Body ──
              Expanded(
                child: _buildBody(vm, isDark),
              ),

              // ── Error / Success Messages ──
              if (vm.errorMessage != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppColors.radiusSm),
                      border:
                          Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Text(
                      vm.errorMessage!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ),
              if (vm.successMessage != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppColors.radiusSm),
                      border:
                          Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Text(
                      vm.successMessage!,
                      style: const TextStyle(
                          color: AppColors.success, fontSize: 13),
                    ),
                  ),
                ),

              // ── Save Button ──
              if (!vm.isLoading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: vm.isSaving
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();
                              final success = await vm.save();
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Preferences saved successfully!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusSm),
                        ),
                      ),
                      child: vm.isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Preferences',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(WorkerCategoryPreferencesViewModel vm, bool isDark) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.allCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No categories available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = vm.groupedCategories;
    final groupNames = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: groupNames.length,
      itemBuilder: (context, groupIndex) {
        final groupName = groupNames[groupIndex];
        final categories = grouped[groupName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Row(
                children: [
                  Icon(
                    _groupIcon(groupName),
                    size: 18,
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    groupName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // Category chips in a wrap
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppColors.radius),
                boxShadow: AppColors.cardShadow(isDark),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((category) {
                  final isSelected =
                      vm.selectedCategoryIds.contains(category.id);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      vm.toggleCategory(category.id);
                    },
                    child: AnimatedContainer(
                      duration: AppColors.animFast,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryBlue.withOpacity(0.12)
                            : (isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.shade100),
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusSm),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : (isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey.shade300),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 18,
                            color: isSelected
                                ? AppColors.primaryBlue
                                : (isDark
                                    ? Colors.white38
                                    : Colors.grey.shade400),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _groupIcon(String group) {
    switch (group) {
      case 'Roads & Transportation':
        return Icons.directions_car_rounded;
      case 'Water & Drainage':
        return Icons.water_drop_rounded;
      case 'Waste & Cleanliness':
        return Icons.delete_rounded;
      case 'Trees & Green Spaces':
        return Icons.park_rounded;
      case 'Parks & Public Spaces':
        return Icons.nature_people_rounded;
      case 'Winter Maintenance':
        return Icons.ac_unit_rounded;
      case 'Property & Safety':
        return Icons.security_rounded;
      case 'Utilities & Infrastructure':
        return Icons.electrical_services_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
