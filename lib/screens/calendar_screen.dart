import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  List<TaskModel> _dayTasks = [];
  List<NoteModel> _dayNotes = [];
  Set<String> _datesWithTasks = {};
  Set<String> _datesWithNotes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshCalendar();
  }

  Future<void> _refreshCalendar() async {
    setState(() => _isLoading = true);
    final monthPrefix = DateFormat('yyyy-MM').format(_currentMonth);
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final tasksForDay = await DatabaseService.instance.getTasksByDate(selectedDateStr);
    final notesForDay = await DatabaseService.instance.getNotesByDate(selectedDateStr);
    final taskDates = await DatabaseService.instance.getDatesWithTasks(monthPrefix);
    final noteDates = await DatabaseService.instance.getDatesWithNotes(monthPrefix);

    setState(() {
      _dayTasks = tasksForDay;
      _dayNotes = notesForDay;
      _datesWithTasks = taskDates;
      _datesWithNotes = noteDates;
      _isLoading = false;
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _refreshDayDetails();
  }

  Future<void> _refreshDayDetails() async {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final tasksForDay = await DatabaseService.instance.getTasksByDate(selectedDateStr);
    final notesForDay = await DatabaseService.instance.getNotesByDate(selectedDateStr);
    setState(() {
      _dayTasks = tasksForDay;
      _dayNotes = notesForDay;
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _refreshCalendar();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _refreshCalendar();
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month);
      _selectedDate = now;
    });
    _refreshCalendar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Calendar',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: const Text(
              'Today',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                // Month Header & Navigation
                _buildMonthHeader(),

                // Calendar Grid
                _buildCalendarGrid(),

                const Divider(color: AppTheme.surfaceBorder, height: 1),

                // Selected Day Timeline / Details
                Expanded(
                  child: Container(
                    color: AppTheme.groupedBackground,
                    child: _buildDayDetails(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(_currentMonth),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.primary, size: 28),
                onPressed: _previousMonth,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.primary, size: 28),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfWeek = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7; // Sunday = 0
    final totalSlots = ((firstDayOfWeek + daysInMonth + 6) ~/ 7) * 7;

    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((d) {
              return SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalSlots,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 0.95,
              mainAxisExtent: 44,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - firstDayOfWeek + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox();
              }

              final cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              final dateStr = DateFormat('yyyy-MM-dd').format(cellDate);
              final isSelected = DateFormat('yyyy-MM-dd').format(_selectedDate) == dateStr;
              final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;
              final hasTasks = _datesWithTasks.contains(dateStr);
              final hasNotes = _datesWithNotes.contains(dateStr);

              return GestureDetector(
                onTap: () => _onDateSelected(cellDate),
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isToday
                                ? AppTheme.primary
                                : isSelected
                                    ? AppTheme.primary.withValues(alpha: 0.15)
                                    : Colors.transparent,
                            border: isSelected && !isToday
                                ? Border.all(color: AppTheme.primary, width: 1.5)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$dayNumber',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isToday
                                  ? Colors.white
                                  : isSelected
                                      ? AppTheme.primary
                                      : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Apple Event Dots
                        SizedBox(
                          height: 5,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (hasTasks)
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.accentGreen,
                                  ),
                                ),
                              if (hasNotes)
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.accentAmber,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDayDetails() {
    final selectedStr = DateFormat('EEEE, MMMM d').format(_selectedDate).toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedStr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${_dayTasks.length} tasks • ${_dayNotes.length} notes',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tasks Section
        if (_dayTasks.isNotEmpty) ...[
          ..._dayTasks.map((t) => _buildMiniTaskTile(t)),
          const SizedBox(height: 16),
        ],

        // Notes Section
        if (_dayNotes.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'NOTES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentAmber,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ..._dayNotes.map((n) => _buildMiniNoteTile(n)),
        ],

        if (_dayTasks.isEmpty && _dayNotes.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            alignment: Alignment.center,
            child: const Column(
              children: [
                Icon(Icons.event_available_outlined, size: 36, color: AppTheme.textMuted),
                SizedBox(height: 8),
                Text(
                  'No items scheduled for this day',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMiniTaskTile(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 20,
            color: task.isCompleted ? AppTheme.accentGreen : const Color(0xFFC7C7CC),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: task.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (task.dueTime != null)
            Text(
              task.dueTime!,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniNoteTile(NoteModel note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: AppTheme.accentAmber,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (note.content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF3C3C43), height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}
