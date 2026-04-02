import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../ViewModels/worker_category_preferences_view_model.dart';
import '../../constants/colors.dart';
import '../../Models/category_model.dart';

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
                        'Set Job Priorities',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? AppColors.darkText2 : AppColors.darkText,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded),
                      onPressed: () {},
                      color: isDark ? AppColors.darkText2 : AppColors.darkText,
                    ),
                  ],
                ),
              ),

              // ── Description ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Choose your priority levels for different job categories.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Body ──
              Expanded(
                child: _buildBody(vm, isDark, context),
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

  Widget _buildBody(
      WorkerCategoryPreferencesViewModel vm, bool isDark, BuildContext context) {
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

    // Show selected categories first, then unselected
    final selected = vm.allCategories
        .where((c) => vm.priorities.containsKey(c.id))
        .toList();
    final unselected = vm.allCategories
        .where((c) => !vm.priorities.containsKey(c.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Active priority cards
        ...selected.map((cat) => _PriorityCategoryCard(
              category: cat,
              priority: vm.getPriority(cat.id),
              isDark: isDark,
              onPriorityChanged: (rank) => vm.setPriority(cat.id, rank),
              onRemove: () => vm.removeCategory(cat.id),
            )),

        // Unselected categories section
        if (unselected.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Add Categories',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: unselected.map((cat) {
              return ActionChip(
                avatar: Icon(_categoryIcon(cat.name), size: 18),
                label: Text(cat.name),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  vm.addCategory(cat.id);
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  static IconData _categoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('plumb') || lower.contains('pipe'))
      return Icons.plumbing_rounded;
    if (lower.contains('electr') || lower.contains('wiring'))
      return Icons.lightbulb_rounded;
    if (lower.contains('carpent') || lower.contains('wood'))
      return Icons.carpenter_rounded;
    if (lower.contains('hvac') ||
        lower.contains('heating') ||
        lower.contains('cooling'))
      return Icons.hvac_rounded;
    if (lower.contains('paint'))
      return Icons.format_paint_rounded;
    if (lower.contains('road') || lower.contains('transport'))
      return Icons.directions_car_rounded;
    if (lower.contains('water') || lower.contains('drain'))
      return Icons.water_drop_rounded;
    if (lower.contains('waste') || lower.contains('clean'))
      return Icons.delete_rounded;
    if (lower.contains('tree') || lower.contains('green'))
      return Icons.park_rounded;
    if (lower.contains('park') || lower.contains('public'))
      return Icons.nature_people_rounded;
    if (lower.contains('winter') || lower.contains('snow'))
      return Icons.ac_unit_rounded;
    if (lower.contains('safety') || lower.contains('property'))
      return Icons.security_rounded;
    if (lower.contains('utilit') || lower.contains('infra'))
      return Icons.electrical_services_rounded;
    return Icons.category_rounded;
  }
}

/// A single category card with a 3-step priority slider.
class _PriorityCategoryCard extends StatelessWidget {
  final Category category;
  final int priority; // 1=Low, 2=Medium, 3=High
  final bool isDark;
  final ValueChanged<int> onPriorityChanged;
  final VoidCallback onRemove;

  const _PriorityCategoryCard({
    required this.category,
    required this.priority,
    required this.isDark,
    required this.onPriorityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = WorkerCategoryPreferencesViewModel.priorityColor(priority);
    final label = WorkerCategoryPreferencesViewModel.priorityLabel(priority);
    final isHigh = priority == 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(
          color: isHigh
              ? const Color(0xFFFFA726).withOpacity(0.5)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
          width: isHigh ? 1.5 : 1,
        ),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
        child: Column(
          children: [
            // Top row: icon + name + remove
            Row(
              children: [
                // Category icon in a circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _PreferencesContent._categoryIcon(category.name),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkText2 : AppColors.darkText,
                    ),
                  ),
                ),
                // Remove button
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Slider row
            Row(
              children: [
                // Labels above slider
                Expanded(
                  child: Column(
                    children: [
                      // Label row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Low',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade500,
                              )),
                          Text('Medium',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade500,
                              )),
                          // High label or badge
                          if (isHigh)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'High Priority',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Text('High',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade500,
                                )),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Custom slider
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: color,
                          inactiveTrackColor:
                              isDark ? Colors.white12 : Colors.grey.shade300,
                          thumbColor: Colors.white,
                          overlayColor: color.withOpacity(0.15),
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10),
                          trackHeight: 6,
                        ),
                        child: Slider(
                          value: priority.toDouble(),
                          min: 1,
                          max: 3,
                          divisions: 2,
                          onChanged: (val) {
                            HapticFeedback.selectionClick();
                            onPriorityChanged(val.round());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
