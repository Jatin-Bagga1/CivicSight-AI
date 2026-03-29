import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../ViewModels/worker_dashboard_view_model.dart';
import '../../Utils/app_router.dart';
import '../../constants/colors.dart';
import '../../Services/map_settings_provider.dart';
import '../../Services/auth_service.dart';

class WorkerDashboardScreen extends StatelessWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorkerDashboardViewModel(),
      child: const _WorkerDashboardContent(),
    );
  }
}

class _WorkerDashboardContent extends StatefulWidget {
  const _WorkerDashboardContent();

  @override
  State<_WorkerDashboardContent> createState() => _WorkerDashboardContentState();
}

class _WorkerDashboardContentState extends State<_WorkerDashboardContent> {
  Color _shiftColor(String status) {
    switch (status) {
      case 'on_duty':
        return AppColors.success;
      case 'break':
        return AppColors.warning;
      case 'off_duty':
      default:
        return Colors.grey;
    }
  }

  String _shiftLabel(String status) {
    switch (status) {
      case 'on_duty':
        return 'On Duty';
      case 'break':
        return 'Break';
      case 'off_duty':
      default:
        return 'Off Duty';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'open':
      case 'assigned':
        return AppColors.info;
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return Colors.grey;
      case 'pending':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  Color _severityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkerDashboardViewModel>();
    final mapSettings = context.watch<MapSettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header (mirrors citizen dashboard) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Name + role badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.fullName ?? 'Worker',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkText2
                                  : AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '🔧 Field Worker',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Shift status badge
                              GestureDetector(
                                onTap: () => _showShiftMenu(context, vm),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _shiftColor(vm.shiftStatus),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (vm.isUpdatingShift)
                                        const SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      else
                                        const Icon(Icons.work_history,
                                            size: 11, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        _shiftLabel(vm.shiftStatus),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action icons
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: vm.fetchTasks,
                      color: isDark ? AppColors.darkText2 : AppColors.darkText,
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_outline_rounded),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRouter.citizenProfile),
                      color: isDark ? AppColors.darkText2 : AppColors.darkText,
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded),
                      onPressed: () => _showLogoutDialog(context),
                      color: isDark ? AppColors.darkText2 : AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),
              // Map Mode Toggle
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
                      Expanded(
                        child: GestureDetector(
                          onTap: () => vm.toggleMapMode(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !vm.showAllReports
                                  ? AppColors.primaryBlue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_pin_circle,
                                  size: 16,
                                  color: !vm.showAllReports
                                      ? Colors.white
                                      : (isDark ? Colors.white60 : Colors.black54),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'My Assigned',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: !vm.showAllReports
                                        ? Colors.white
                                        : (isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => vm.toggleMapMode(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: vm.showAllReports
                                  ? AppColors.primaryBlue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map,
                                  size: 16,
                                  color: vm.showAllReports
                                      ? Colors.white
                                      : (isDark ? Colors.white60 : Colors.black54),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'All Reports',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: vm.showAllReports
                                        ? Colors.white
                                        : (isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Map Section
              SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
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

          // Tasks List Background Wrapper
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: AppColors.cardShadow(isDark),
              ),
              child: _buildTaskList(vm, isDark),
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }

  Widget _buildTaskList(WorkerDashboardViewModel vm, bool isDark) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load tasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: vm.fetchTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (vm.assignedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              vm.hasTasks ? 'No tasks match your filters' : 'You have no tasks yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vm.hasTasks ? 'Try changing status, severity, or due-date filters.' : 'Enjoy your break!',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assigned Tasks (${vm.assignedTasks.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  initialValue: vm.statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                    DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  ],
                  onChanged: (value) {
                    if (value != null) vm.updateStatusFilter(value);
                  },
                ),
              ),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  initialValue: vm.severityFilter,
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'high', child: Text('High (4-5)')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium (3)')),
                    DropdownMenuItem(value: 'low', child: Text('Low (1-2)')),
                  ],
                  onChanged: (value) {
                    if (value != null) vm.updateSeverityFilter(value);
                  },
                ),
              ),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  initialValue: vm.dueFilter,
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'today', child: Text('Due Today')),
                    DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                    DropdownMenuItem(value: 'next3', child: Text('Next 3 Days')),
                  ],
                  onChanged: (value) {
                    if (value != null) vm.updateDueFilter(value);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: vm.fetchTasks,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: vm.assignedTasks.length,
              itemBuilder: (_, index) => _buildReportCard(vm.assignedTasks[index], isDark),
            ),
          ),
        ),
      ],
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

  Widget _buildReportCard(Map<String, dynamic> report, bool isDark) {
    final reportId = report['id'] as String? ?? '';
    final reportNumber = report['report_number'] ?? '-';
    final status = report['status'] as String? ?? 'assigned';
    final category = report['ai_category_name'] as String? ?? 'Unknown';
    final severity = (report['ai_severity'] as num?)?.toInt() ?? 0;
    final description = report['description'] as String? ?? '';
    final reportedAt = report['reported_at'] as String?;

    // Get primary image
    final images = report['report_images'] as List? ?? [];
    String? imageUrl;
    if (images.isNotEmpty) {
      imageUrl = images.first['image_url'] as String?;
    }

    // Get location
    final locations = report['report_locations'];
    String? address;
    if (locations is Map) {
      address = locations['formatted_address'] as String?;
    } else if (locations is List && locations.isNotEmpty) {
      address = locations.first['formatted_address'] as String?;
    }

    // Format date
    String dateStr = '';
    if (reportedAt != null) {
      final dt = DateTime.tryParse(reportedAt);
      if (dt != null) {
        dateStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.taskDetail,
          arguments: reportId,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppColors.radius),
          boxShadow: AppColors.cardShadow(isDark),
          border: Border.all(
            color: (status == 'resolved' || status == 'completed')
                ? AppColors.success.withOpacity(0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Status overlay
            if (imageUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.radius)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.broken_image, size: 40)),
                      ),
                    ),
                  ),
                  Positioned(top: 8, right: 8, child: _statusChip(status)),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$reportNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 14, right: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#$reportNumber',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    _statusChip(status),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + Severity
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (severity > 0) ...[
                        Icon(
                          Icons.warning_rounded,
                          size: 16,
                          color: _severityColor(severity),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Severity $severity/5',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _severityColor(severity),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Description
                  if (description.isNotEmpty)
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.4,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Location
                  if (address != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 6),

                  // Date
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status),
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showShiftMenu(BuildContext context, WorkerDashboardViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.radius)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Set Shift Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.work, color: AppColors.success),
              title: const Text('On Duty'),
              onTap: () {
                Navigator.pop(context);
                vm.updateShiftStatus('on_duty');
              },
            ),
            ListTile(
              leading: const Icon(Icons.coffee, color: AppColors.warning),
              title: const Text('Break'),
              onTap: () {
                Navigator.pop(context);
                vm.updateShiftStatus('break');
              },
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.grey),
              title: const Text('Off Duty'),
              onTap: () {
                Navigator.pop(context);
                vm.updateShiftStatus('off_duty');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radius)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
              ),
            ),
            onPressed: () async {
              await AuthService().logout();
              HapticFeedback.mediumImpact();
              if (context.mounted) {
                Navigator.pop(context);
                AppRouter.navigateAndClearAll(context, AppRouter.login);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
