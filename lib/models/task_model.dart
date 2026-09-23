class TaskModel {
  final int? id;
  final String title;
  final String? description;
  final String dueDate; // Format: YYYY-MM-DD
  final String? dueTime; // Format: HH:mm
  final String priority; // 'high', 'medium', 'low'
  final String category; // 'Work', 'Personal', 'Fitness', 'Study', 'Routine', 'Other'
  final bool isCompleted;
  final String? reminderDateTime; // ISO-8601 string
  final int? notificationId;

  TaskModel({
    this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.dueTime,
    this.priority = 'medium',
    this.category = 'Personal',
    this.isCompleted = false,
    this.reminderDateTime,
    this.notificationId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'dueTime': dueTime,
      'priority': priority,
      'category': category,
      'isCompleted': isCompleted ? 1 : 0,
      'reminderDateTime': reminderDateTime,
      'notificationId': notificationId,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: map['dueDate'] as String,
      dueTime: map['dueTime'] as String?,
      priority: (map['priority'] as String?) ?? 'medium',
      category: (map['category'] as String?) ?? 'Personal',
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      reminderDateTime: map['reminderDateTime'] as String?,
      notificationId: map['notificationId'] as int?,
    );
  }

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    String? dueDate,
    String? dueTime,
    String? priority,
    String? category,
    bool? isCompleted,
    String? reminderDateTime,
    int? notificationId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      notificationId: notificationId ?? this.notificationId,
    );
  }
}
