import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ViewModels/worker_dashboard_view_model.dart';
import '../../Utils/app_router.dart';
import '../../constants/colors.dart';

/// History screen showing completed/closed tasks with filters.
class WorkerHistoryScreen extends StatelessWidget {
  const WorkerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkerDashboardViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _buildBody(context, vm, isDark);
  }

  Widget _buildBody(
      BuildContext context, WorkerDashboardViewModel vm, bool isDark) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!vm.hasHistory) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No task history yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed tasks will appear here.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header + count ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'History (${vm.historyTasks.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText2 : AppColors.darkText,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: vm.fetchTasks,
                color: isDark ? AppColors.darkText2 : AppColors.darkText,
              ),
            ],
          ),
        ),

        // ── Filters ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Time filter
              _buildDropdown(
                width: 140,
                label: 'Time',
                value: vm.historyTimeFilter,
                isDark: isDark,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Time')),
                  DropdownMenuItem(value: 'today', child: Text('Today')),
                  DropdownMenuItem(value: 'week', child: Text('This Week')),
                  DropdownMenuItem(value: 'month', child: Text('This Month')),
                  DropdownMenuItem(value: 'quarter', child: Text('3 Months')),
                ],
                onChanged: (v) {
                  if (v != null) vm.updateHistoryTimeFilter(v);
                },
              ),

              // Category filter
              _buildDropdown(
                width: 160,
                label: 'Category',
                value: vm.historyCategoryFilter,
                isDark: isDark,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All Categories')),
                  ...vm.historyCategories.map(
                    (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) vm.updateHistoryCategoryFilter(v);
                },
              ),

              // Severity filter
              _buildDropdown(
                width: 140,
                label: 'Severity',
                value: vm.historySeverityFilter,
                isDark: isDark,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'high', child: Text('High (4-5)')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium (3)')),
                  DropdownMenuItem(value: 'low', child: Text('Low (1-2)')),
                ],
                onChanged: (v) {
                  if (v != null) vm.updateHistorySeverityFilter(v);
                },
              ),

              // Status filter
              _buildDropdown(
                width: 140,
                label: 'Status',
                value: vm.historyStatusFilter,
                isDark: isDark,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                ],
                onChanged: (v) {
                  if (v != null) vm.updateHistoryStatusFilter(v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Task Cards ──
        Expanded(
          child: vm.historyTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_list_off,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No tasks match your filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: vm.fetchTasks,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: vm.historyTasks.length,
                    itemBuilder: (_, index) =>
                        _buildHistoryCard(context, vm.historyTasks[index], isDark),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required double width,
    required String label,
    required String value,
    required bool isDark,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            borderSide: BorderSide(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
          ),
        ),
        dropdownColor: isDark ? AppColors.darkCard : Colors.white,
        style: TextStyle(
          color: isDark ? AppColors.darkText2 : AppColors.darkText,
          fontSize: 14,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  // ── History card ──

  Color _statusColor(String? status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'resolved':
        return AppColors.primaryBlue;
      case 'closed':
        return Colors.grey;
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

  Widget _buildHistoryCard(
      BuildContext context, Map<String, dynamic> report, bool isDark) {
    final reportId = report['id'] as String? ?? '';
    final reportNumber = report['report_number'] ?? '-';
    final status = report['status'] as String? ?? 'completed';
    final category = report['ai_category_name'] as String? ?? 'Unknown';
    final severity = (report['ai_severity'] as num?)?.toInt() ?? 0;
    final description = report['description'] as String? ?? '';
    final completedAt = report['completed_at'] as String?;

    // Primary image
    final images = report['report_images'] as List? ?? [];
    String? imageUrl;
    if (images.isNotEmpty) {
      imageUrl = images.first['image_url'] as String?;
    }

    // Location
    final locations = report['report_locations'];
    String? address;
    if (locations is Map) {
      address = locations['formatted_address'] as String?;
    } else if (locations is List && locations.isNotEmpty) {
      address = locations.first['formatted_address'] as String?;
    }

    // Completed date
    String dateStr = '';
    if (completedAt != null) {
      final dt = DateTime.tryParse(completedAt);
      if (dt != null) {
        final local = dt.toLocal();
        dateStr =
            '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + status overlay
            if (imageUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppColors.radius)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: Colors.grey.shade200,
                        child: const Center(
                            child: Icon(Icons.broken_image, size: 40)),
                      ),
                    ),
                  ),
                  Positioned(top: 8, right: 8, child: _statusChip(status)),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? AppColors.darkText2 : AppColors.darkText,
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
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 6),

                  // Completed date
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        dateStr.isNotEmpty ? 'Completed: $dateStr' : '',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
