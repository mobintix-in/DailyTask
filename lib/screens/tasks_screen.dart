import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  String _selectedFilter = 'Today'; // Today, All, Upcoming, High Priority, Completed
  Map<String, int> _todayStats = {'total': 0, 'completed': 0};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final allTasks = await DatabaseService.instance.getAllTasks();
    final stats = await DatabaseService.instance.getTodayTaskStats(todayStr);

    setState(() {
      _tasks = allTasks;
      _todayStats = stats;
      _isLoading = false;
    });
  }

  List<TaskModel> get _filteredTasks {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    switch (_selectedFilter) {
      case 'Today':
        return _tasks.where((t) => t.dueDate == todayStr).toList();
      case 'Upcoming':
        return _tasks.where((t) => t.dueDate.compareTo(todayStr) > 0).toList();
      case 'High Priority':
        return _tasks.where((t) => t.priority.toLowerCase() == 'high').toList();
      case 'Completed':
        return _tasks.where((t) => t.isCompleted).toList();
      case 'All':
      default:
        return _tasks;
    }
  }

  Future<void> _toggleTaskCompletion(TaskModel task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await DatabaseService.instance.updateTask(updated);

    if (updated.isCompleted && updated.notificationId != null) {
      await NotificationService.instance.cancelNotification(updated.notificationId!);
    } else if (!updated.isCompleted && updated.reminderDateTime != null) {
      await NotificationService.instance.scheduleTaskNotification(updated);
    }

    _loadTasks();
  }

  Future<void> _deleteTask(TaskModel task) async {
    if (task.id != null) {
      await DatabaseService.instance.deleteTask(task.id!);
      if (task.notificationId != null) {
        await NotificationService.instance.cancelNotification(task.notificationId!);
      }
      _loadTasks();
      if (mounted) {
        AppToast.info(
          context,
          'Deleted "${task.title}"',
          icon: Icons.delete_outline_rounded,
          actionLabel: 'Undo',
          onAction: () async {
            await DatabaseService.instance.insertTask(task);
            _loadTasks();
          },
        );
      }
    }
  }

  void _showAddEditTaskSheet([TaskModel? taskToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskFormSheet(
        task: taskToEdit,
        onSaved: _loadTasks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks;
    final total = _todayStats['total'] ?? 0;
    final completed = _todayStats['completed'] ?? 0;
    final completionRate = total > 0 ? (completed / total) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.groupedBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.groupedBackground,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()).toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const Text(
              'My Day',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
            onPressed: _loadTasks,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: Colors.white,
              onRefresh: _loadTasks,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Apple-style Productivity Summary Card
                  _buildProgressCard(total, completed, completionRate),
                  const SizedBox(height: 16),

                  // Cupertino Segmented Control Filter Bar
                  _buildFilterSegments(),
                  const SizedBox(height: 16),

                  // Tasks List
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else
                    ...filtered.map((task) => _buildTaskCard(task)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tasks_fab',
        onPressed: () => _showAddEditTaskSheet(),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'New Task',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2),
        ),
      ),
    );
  }

  Widget _buildProgressCard(int total, int completed, double rate) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.apple_rounded, size: 16, color: AppTheme.textSecondary),
                    SizedBox(width: 6),
                    Text(
                      'Daily Summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  total == 0
                      ? 'No tasks scheduled for today yet.'
                      : completed == total
                          ? '🎉 All tasks completed! Great work.'
                          : '$completed of $total tasks done (${(rate * 100).toInt()}%)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0.0 : rate,
                    backgroundColor: AppTheme.surfaceElevated,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                    minHeight: 7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 1.2),
            ),
            child: Center(
              child: Text(
                '${(rate * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSegments() {
    final filters = ['Today', 'All', 'Upcoming', 'High Priority', 'Completed'];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final priorityColor = AppTheme.priorityColor(task.priority);
    final categoryColor = AppTheme.categoryColor(task.category);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.accentCoral,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      onDismissed: (_) => _deleteTask(task),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.surfaceBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showAddEditTaskSheet(task),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Apple Reminders Style Circular Checkbox
                GestureDetector(
                  onTap: () => _toggleTaskCompletion(task),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(top: 2, right: 14),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted ? AppTheme.accentGreen : Colors.transparent,
                      border: Border.all(
                        color: task.isCompleted ? AppTheme.accentGreen : const Color(0xFFC7C7CC),
                        width: 1.8,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),

                // Task Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: task.isCompleted
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          decoration:
                              task.isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: AppTheme.textSecondary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (task.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: task.isCompleted
                                ? AppTheme.textMuted
                                : AppTheme.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Meta Chips Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Category Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: categoryColor,
                              ),
                            ),
                          ),
                          // Priority Chip
                          if (task.priority.toLowerCase() != 'low')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task.priority.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: priorityColor,
                                ),
                              ),
                            ),
                          // Date/Time
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 12, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                task.dueTime != null
                                    ? '${task.dueDate} • ${task.dueTime}'
                                    : task.dueDate,
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                          // Reminder Indicator
                          if (task.reminderDateTime != null)
                            const Icon(
                              Icons.notifications_active_rounded,
                              size: 13,
                              color: AppTheme.accentAmber,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Edit Button
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 20, color: AppTheme.textSecondary),
                  onPressed: () => _showAddEditTaskSheet(task),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceElevated,
            ),
            child: const Icon(
              Icons.checklist_rounded,
              size: 44,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Tasks Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "New Task" to create your first reminder.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TaskFormSheet extends StatefulWidget {
  final TaskModel? task;
  final VoidCallback onSaved;

  const _TaskFormSheet({this.task, required this.onSaved});

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  String _priority = 'medium';
  String _category = 'Personal';
  bool _enableReminder = false;

  final List<String> _categories = ['Work', 'Personal', 'Fitness', 'Study', 'Routine', 'Other'];
  final List<String> _priorities = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _selectedDate = t != null ? DateTime.parse(t.dueDate) : DateTime.now();
    if (t?.dueTime != null) {
      final parts = t!.dueTime!.split(':');
      _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    _priority = t?.priority ?? 'medium';
    _category = t?.category ?? 'Personal';
    _enableReminder = t?.reminderDateTime != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final timeStr = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : null;

    String? reminderIso;
    int? notifId = widget.task?.notificationId;

    if (_enableReminder) {
      final timeParts = (timeStr ?? '09:00').split(':');
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      reminderIso = scheduledDateTime.toIso8601String();
      notifId ??= DateTime.now().millisecondsSinceEpoch.remainder(100000);
    } else {
      notifId = null;
    }

    final taskToSave = TaskModel(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      dueDate: dateStr,
      dueTime: timeStr,
      priority: _priority,
      category: _category,
      isCompleted: widget.task?.isCompleted ?? false,
      reminderDateTime: reminderIso,
      notificationId: notifId,
    );

    if (widget.task == null) {
      final insertedId = await DatabaseService.instance.insertTask(taskToSave);
      final completeTask = taskToSave.copyWith(id: insertedId);
      if (_enableReminder) {
        await NotificationService.instance.scheduleTaskNotification(completeTask);
      }
    } else {
      await DatabaseService.instance.updateTask(taskToSave);
      if (_enableReminder) {
        await NotificationService.instance.scheduleTaskNotification(taskToSave);
      } else if (widget.task?.notificationId != null) {
        await NotificationService.instance.cancelNotification(widget.task!.notificationId!);
      }
    }

    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.task == null ? 'New Reminder' : 'Edit Reminder',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g. Finish quarterly project proposal',
                  prefixIcon: Icon(Icons.title_rounded, color: AppTheme.primary),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),

              // Description Field
              TextFormField(
                controller: _descController,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add details, sub-notes, links...',
                  prefixIcon: Icon(Icons.notes_rounded, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 16),

              // Date & Time Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        backgroundColor: AppTheme.surfaceElevated,
                        side: const BorderSide(color: AppTheme.surfaceBorder, width: 0.8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 16, color: AppTheme.primary),
                      label: Text(
                        DateFormat('MMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        backgroundColor: AppTheme.surfaceElevated,
                        side: const BorderSide(color: AppTheme.surfaceBorder, width: 0.8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.accentAmber),
                      label: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Set Time',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Selector
              const Text(
                'Category',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSel = _category == cat;
                    final catColor = AppTheme.categoryColor(cat);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: catColor,
                        backgroundColor: AppTheme.surfaceElevated,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppTheme.textPrimary,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: isSel ? catColor : AppTheme.surfaceBorder,
                          width: 0.8,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (_) => setState(() => _category = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Priority Selector (Apple Segmented Style)
              const Text(
                'Priority',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((p) {
                  final isSel = _priority == p;
                  final pColor = AppTheme.priorityColor(p);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => setState(() => _priority = p),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? pColor.withValues(alpha: 0.12) : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? pColor : AppTheme.surfaceBorder,
                              width: isSel ? 1.8 : 0.8,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            p.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSel ? pColor : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Notification Reminder Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTheme.primary,
                activeTrackColor: AppTheme.primary.withValues(alpha: 0.35),
                title: const Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, color: AppTheme.accentAmber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Schedule Offline Notification',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                subtitle: const Text(
                  'Local phone alarm without internet',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                value: _enableReminder,
                onChanged: (val) => setState(() => _enableReminder = val),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _save,
                  child: Text(
                    widget.task == null ? 'Create Task' : 'Update Task',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
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
}
