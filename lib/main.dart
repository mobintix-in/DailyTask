import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/security_service.dart';
import 'theme/app_theme.dart';
import 'screens/tasks_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/pin_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline local notifications
  await NotificationService.instance.init();

  // Wipe all existing local tasks & notes to start completely clean
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('has_wiped_all_local_data_v1') != true) {
    await DatabaseService.instance.clearAllData();
    await NotificationService.instance.cancelAllNotifications();
    await prefs.setBool('has_wiped_all_local_data_v1', true);
  }

  // Check if App Lock PIN is enabled
  final isLockEnabled = await SecurityService.instance.isLockEnabled();

  runApp(DailyTaskApp(requiresPinOnStart: isLockEnabled));
}

class DailyTaskApp extends StatefulWidget {
  final bool requiresPinOnStart;

  const DailyTaskApp({super.key, required this.requiresPinOnStart});

  @override
  State<DailyTaskApp> createState() => _DailyTaskAppState();
}

class _DailyTaskAppState extends State<DailyTaskApp>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isLocked = widget.requiresPinOnStart;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      SecurityService.instance.recordPauseTime();
    } else if (state == AppLifecycleState.resumed) {
      _checkAutoLock();
    }
  }

  Future<void> _checkAutoLock() async {
    final shouldLock = await SecurityService.instance.shouldLockOnResume();
    if (shouldLock && mounted && !_isLocked) {
      setState(() => _isLocked = true);
    }
  }

  void _onUnlocked() {
    setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'DailyTask',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isLocked
          ? PinLockScreen(
              mode: PinMode.unlock,
              onSuccess: _onUnlocked,
            )
          : const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TasksScreen(),
    const CalendarScreen(),
    const NotesScreen(),
    const PrivacyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.surfaceBorder, width: 0.8),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(0, Icons.check_circle_outline_rounded, Icons.check_circle_rounded, 'Tasks'),
                _buildTabItem(1, Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Calendar'),
                _buildTabItem(2, Icons.sticky_note_2_outlined, Icons.sticky_note_2_rounded, 'Notes'),
                _buildTabItem(3, Icons.shield_outlined, Icons.shield_rounded, 'Privacy'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
