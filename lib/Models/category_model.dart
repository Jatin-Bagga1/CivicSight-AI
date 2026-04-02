/// Model representing a row in the `categories` Supabase table.
class Category {
  final int id;
  final String name;
  final String exampleIssues;
  final String categoryGroup;
  final int minResponseDays;
  final int maxResponseDays;
  final bool isActive;
  final DateTime? createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.exampleIssues,
    required this.categoryGroup,
    this.minResponseDays = 1,
    this.maxResponseDays = 14,
    this.isActive = true,
    this.createdAt,
  });

  factory Category.fromSupabase(Map<String, dynamic> map) {
    return Category(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String,
      exampleIssues: map['example_issues'] as String? ?? '',
      categoryGroup: map['category_group'] as String? ?? '',
      minResponseDays: (map['min_response_days'] as num?)?.toInt() ?? 1,
      maxResponseDays: (map['max_response_days'] as num?)?.toInt() ?? 14,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'example_issues': exampleIssues,
      'category_group': categoryGroup,
      'min_response_days': minResponseDays,
      'max_response_days': maxResponseDays,
      'is_active': isActive,
    };
  }
}

/// Model representing a row in the `worker_category_preferences` table.
class WorkerCategoryPreference {
  final int? id;
  final String workerId;
  final int categoryId;
  final int priorityRank;
  final DateTime? createdAt;

  const WorkerCategoryPreference({
    this.id,
    required this.workerId,
    required this.categoryId,
    this.priorityRank = 1,
    this.createdAt,
  });

  factory WorkerCategoryPreference.fromSupabase(Map<String, dynamic> map) {
    return WorkerCategoryPreference(
      id: (map['id'] as num?)?.toInt(),
      workerId: map['worker_id'] as String,
      categoryId: (map['category_id'] as num).toInt(),
      priorityRank: (map['priority_rank'] as num?)?.toInt() ?? 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'worker_id': workerId,
      'category_id': categoryId,
      'priority_rank': priorityRank,
    };
  }
}
