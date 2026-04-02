import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../ViewModels/worker_dashboard_view_model.dart';
import '../../Services/map_settings_provider.dart';
import '../../constants/colors.dart';

/// Worker home tab — map + toggle + metric cards (no task list).
class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkerDashboardViewModel>();
    final mapSettings = context.watch<MapSettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ── Map Mode Toggle ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _toggleButton(
                  label: 'My Assigned',
                  icon: Icons.person_pin_circle,
                  isActive: !vm.showAllReports,
                  isDark: isDark,
                  onTap: () => vm.toggleMapMode(false),
                ),
                _toggleButton(
                  label: 'All Reports',
                  icon: Icons.map,
                  isActive: vm.showAllReports,
                  isDark: isDark,
                  onTap: () => vm.toggleMapMode(true),
                ),
              ],
            ),
          ),
        ),

        // ── Map ──
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: vm.currentLocation,
              zoom: 13,
            ),
            onMapCreated: (controller) {
              if (vm.locationLoaded) {
                controller.animateCamera(
                  CameraUpdate.newLatLng(vm.currentLocation),
                );
              }
            },
            markers: vm.markers,
            mapType: mapSettings.mapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
        ),

        // ── Metric Cards ──
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: AppColors.cardShadow(isDark),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _metricCard(
                    title: 'Total',
                    value: vm.totalTasksCount.toString(),
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 10),
                  _metricCard(
                    title: 'In Progress',
                    value: vm.inProgressCount.toString(),
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  _metricCard(
                    title: 'Resolved Today',
                    value: vm.completedTodayCount.toString(),
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  _metricCard(
                    title: 'Overdue',
                    value: vm.overdueCount.toString(),
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 10),
                  _metricCard(
                    title: 'Avg Hours',
                    value: vm.averageCompletionHours.toStringAsFixed(1),
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
