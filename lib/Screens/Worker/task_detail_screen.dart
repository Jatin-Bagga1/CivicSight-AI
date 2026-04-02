import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ViewModels/worker_task_detail_view_model.dart';
import '../../Services/supabase_service.dart';
import '../../constants/colors.dart';

class TaskDetailScreen extends StatelessWidget {
  final String reportId;

  const TaskDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorkerTaskDetailViewModel(reportId),
      child: const _TaskDetailContent(),
    );
  }
}

class _TaskDetailContent extends StatefulWidget {
  const _TaskDetailContent();

  @override
  State<_TaskDetailContent> createState() => _TaskDetailContentState();
}

class _TaskDetailContentState extends State<_TaskDetailContent> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _commentScrollController = ScrollController();
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = false;
  bool _sendingComment = false;
  RealtimeChannel? _commentChannel;

  @override
  void initState() {
    super.initState();
  }

  void _tryLoadComments(WorkerTaskDetailViewModel vm) {
    final reportId = vm.taskDetails?['id'] as String? ?? '';
    if (reportId.isNotEmpty && _comments.isEmpty && !_loadingComments) {
      _loadComments(reportId);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentScrollController.dispose();
    _commentChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadComments(String reportId) async {
    if (reportId.isEmpty) return;
    setState(() => _loadingComments = true);
    try {
      final comments = await _supabaseService.getComments(reportId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _loadingComments = false;
        });
        _scrollToBottom();
        _subscribeToComments(reportId);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  void _subscribeToComments(String reportId) {
    _commentChannel?.unsubscribe();
    _commentChannel = _supabaseService.subscribeToComments(
      reportId,
      (newComment) {
        if (mounted) {
          setState(() => _comments.add(newComment));
          _scrollToBottom();
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_commentScrollController.hasClients) {
        _commentScrollController.animateTo(
          _commentScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendComment(String reportId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty || reportId.isEmpty) return;

    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid == null) return;

    setState(() => _sendingComment = true);
    try {
      await _supabaseService.addComment(
        reportId: reportId,
        userId: firebaseUid,
        content: text,
      );
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  void _showImageSourceSheet(WorkerTaskDetailViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Add Proof of Completion',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryBlue),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use your camera to capture an image'),
                onTap: () {
                  Navigator.pop(context);
                  vm.pickProofImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryOrange),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing image from your device'),
                onTap: () {
                  Navigator.pop(context);
                  vm.pickProofImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkerTaskDetailViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for errors
    if (vm.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar(vm.errorMessage!, isError: true);
        // We cannot clear error in build, so just display it.
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: _buildBody(vm, isDark),
    );
  }

  Widget _buildBody(WorkerTaskDetailViewModel vm, bool isDark) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.taskDetails == null) {
      return const Center(child: Text('Task not found.'));
    }

    // Load comments once task details are available
    _tryLoadComments(vm);

    final task = vm.taskDetails!;
    final reportNumber = task['report_number'] ?? '-';
    final status = task['status'] as String? ?? 'assigned';
    final category = task['ai_category_name'] as String? ?? 'Unknown';
    final description = task['description'] as String? ?? '';
    final severity = (task['ai_severity'] as num?)?.toInt() ?? 0;
    
    // Original images
    final images = task['report_images'] as List? ?? [];
    String? primaryImageUrl;
    String? proofImageUrl;

    for (var img in images) {
      if (img['is_primary'] == true) {
        primaryImageUrl = img['image_url'];
      } else {
        proofImageUrl = img['image_url']; // secondary images = proof
      }
    }
    
    if (primaryImageUrl == null && images.isNotEmpty) {
      primaryImageUrl = images.first['image_url']; // fallback
    }

    final locations = task['report_locations'];
    String? address;
    if (locations is Map) {
      address = locations['formatted_address'] as String?;
    } else if (locations is List && locations.isNotEmpty) {
      address = locations.first['formatted_address'] as String?;
    }

    final isResolved = status == 'completed' || status == 'resolved';

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
             gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primary Image
                if (primaryImageUrl != null)
                  Container(
                    width: double.infinity,
                    height: 220,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(primaryImageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: Icon(Icons.image_not_supported, size: 40)),
                  ),

                // Title & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#$reportNumber',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Text('Update Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                TextField(
                  minLines: 2,
                  maxLines: 3,
                  onChanged: vm.setUpdateNote,
                  decoration: InputDecoration(
                    hintText: 'Add field notes for this update',
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Category & Severity
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Severity: $severity / 5',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.error),
                ),
                const SizedBox(height: 16),
                
                // Description
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(fontSize: 15, color: isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(height: 16),

                // Location
                const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_pin, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address ?? 'Unknown Location',
                        style: TextStyle(fontSize: 15, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Comments Section ──
                _buildCommentsSection(task['id'] as String? ?? '', isDark),

                const SizedBox(height: 32),
                
                // Proof Image Section (if resolved or attempting to resolve)
                if (isResolved && proofImageUrl != null) ...[
                  const Text('Proof of Resolution:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(proofImageUrl, width: double.infinity, height: 200, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 32),
                ] else if (!isResolved) ...[
                  const Text('Resolve Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  
                  // In Progress Button
                  if (status == 'assigned')
                     SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => vm.updateStatus('in_progress'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Mark as "In Progress"'),
                      ),
                    ),
                  
                  if (status == 'assigned') const SizedBox(height: 24),

                  if (vm.hasProofImage)
                     Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(vm.proofImage!, width: double.infinity, height: 200, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: vm.removeProofImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                     )
                  else
                     GestureDetector(
                      onTap: () => _showImageSourceSheet(vm),
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.5), width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt, color: AppColors.primaryBlue, size: 30),
                            const SizedBox(height: 8),
                            Text('Attach Proof Image', style: TextStyle(color: AppColors.primaryBlue.withOpacity(0.8), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                  
                  // Submit Resolution
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: vm.hasProofImage ? () async {
                        final success = await vm.resolveTask();
                        if (success && mounted) {
                          _showSnackBar('Task marked as resolved!');
                        }
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Resolve Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 48), // Bottom padding
                ],
              ],
            ),
          ),
        ),

        // Upload overlay
        if (vm.isUploading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      vm.statusMessage,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentsSection(String reportId, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            const Text(
              'Comments',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            if (_comments.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_comments.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Comments list
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: _loadingComments
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : _comments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.forum_outlined, size: 32, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'No comments yet',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start a conversation with admin',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _commentScrollController,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _comments.length,
                      itemBuilder: (_, index) =>
                          _buildCommentBubble(_comments[index], isDark),
                    ),
        ),

        const SizedBox(height: 10),

        // Input row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendComment(reportId),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _sendingComment ? null : () => _sendComment(reportId),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  child: _sendingComment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentBubble(Map<String, dynamic> comment, bool isDark) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isWorker = comment['user_id'] == currentUid;
    final authorName = isWorker ? 'You' : 'Admin';
    final message = comment['content'] as String? ?? '';
    final createdAt = comment['created_at'] as String?;

    String timeStr = '';
    if (createdAt != null) {
      final dt = DateTime.tryParse(createdAt);
      if (dt != null) {
        final local = dt.toLocal();
        timeStr =
            '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isWorker ? 40 : 10,
        4,
        isWorker ? 10 : 40,
        4,
      ),
      child: Align(
        alignment: isWorker ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isWorker
                ? AppColors.primaryBlue
                : (isDark ? Colors.grey.shade800 : Colors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isWorker ? 16 : 4),
              bottomRight: Radius.circular(isWorker ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isWorker ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isWorker)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    authorName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.primaryBlue : AppColors.primaryBlue,
                    ),
                  ),
                ),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: isWorker
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: isWorker
                      ? Colors.white70
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
