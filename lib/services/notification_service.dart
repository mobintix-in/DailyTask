import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task_model.dart';

class NotificationSoundOption {
  final String id;
  final String title;
  final String description;
  final String channelId;
  final String? rawResource;
  final IconData icon;

  const NotificationSoundOption({
    required this.id,
    required this.title,
    required this.description,
    required this.channelId,
    required this.rawResource,
    required this.icon,
  });
}

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  static const String _prefSoundKey = 'daily_task_selected_sound';

  static const List<NotificationSoundOption> soundOptions = [
    NotificationSoundOption(
      id: 'default',
      title: 'Phone Default',
      description: 'Standard device notification tone',
      channelId: 'daily_task_sound_default_v2',
      rawResource: null,
      icon: Icons.phonelink_ring_rounded,
    ),
    NotificationSoundOption(
      id: 'bell',
      title: 'Crystal Bell',
      description: 'Clear, crisp dual-tone bell chime',
      channelId: 'daily_task_sound_bell_v2',
      rawResource: 'sound_bell',
      icon: Icons.notifications_active_rounded,
    ),
    NotificationSoundOption(
      id: 'alarm',
      title: 'Digital Alarm',
      description: 'Bright 4-tone ascending alert',
      channelId: 'daily_task_sound_alarm_v2',
      rawResource: 'sound_alarm',
      icon: Icons.alarm_rounded,
    ),
    NotificationSoundOption(
      id: 'chime',
      title: 'Gentle Chime',
      description: 'Soothing wooden marimba chord',
      channelId: 'daily_task_sound_chime_v2',
      rawResource: 'sound_chime',
      icon: Icons.music_note_rounded,
    ),
  ];

  Future<void> init() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification click if needed
        },
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // 1. Delete legacy silent channels to clear cached system channel settings
        try {
          await androidImplementation.deleteNotificationChannel(
            channelId: 'daily_task_reminders',
          );
          await androidImplementation.deleteNotificationChannel(
            channelId: 'daily_task_sound_default_v1',
          );
        } catch (_) {}

        // 2. Register all sound channels with high importance
        for (final option in soundOptions) {
          final sound = option.rawResource != null
              ? RawResourceAndroidNotificationSound(option.rawResource!)
              : null;

          await androidImplementation.createNotificationChannel(
            AndroidNotificationChannel(
              option.channelId,
              option.title,
              description: option.description,
              importance: Importance.max,
              playSound: true,
              sound: sound,
              enableVibration: true,
              vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
            ),
          );
        }

        // 3. Request permissions safely without concurrency conflicts
        try {
          await androidImplementation.requestNotificationsPermission();
        } catch (e) {
          debugPrint('Notification permission error: $e');
        }

        try {
          final canExact = await androidImplementation.canScheduleExactNotifications();
          if (canExact == false) {
            await androidImplementation.requestExactAlarmsPermission();
          }
        } catch (e) {
          debugPrint('Exact alarm permission error: $e');
        }
      }
    } catch (e, stack) {
      debugPrint('NotificationService init error: $e\n$stack');
    }
  }

  Future<String> getSelectedSoundId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefSoundKey) ?? 'default';
  }

  Future<void> setSelectedSoundId(String soundId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefSoundKey, soundId);
  }

  NotificationSoundOption getSoundOption(String soundId) {
    return soundOptions.firstWhere(
      (opt) => opt.id == soundId,
      orElse: () => soundOptions.first,
    );
  }

  NotificationDetails _buildNotificationDetails(NotificationSoundOption option) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        option.channelId,
        option.title,
        channelDescription: option.description,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: option.rawResource != null
            ? RawResourceAndroidNotificationSound(option.rawResource!)
            : null,
        audioAttributesUsage: option.id == 'alarm'
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
        category: option.id == 'alarm'
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: option.rawResource != null ? '${option.rawResource}.wav' : null,
      ),
    );
  }

  Future<bool> scheduleTaskNotification(TaskModel task) async {
    if (task.reminderDateTime == null) return false;
    try {
      final scheduledDate = DateTime.parse(task.reminderDateTime!);
      if (scheduledDate.isBefore(DateTime.now())) {
        return false; // Don't schedule in the past
      }

      final id = task.notificationId ??
          (task.id ?? DateTime.now().millisecondsSinceEpoch % 100000);

      final soundId = await getSelectedSoundId();
      final option = getSoundOption(soundId);

      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: '⏰ ${task.title}',
          body: task.description?.isNotEmpty == true
              ? task.description
              : 'Scheduled for ${task.dueTime ?? task.dueDate} (${task.priority.toUpperCase()} priority)',
          scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails: _buildNotificationDetails(option),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        return true;
      } catch (exactError) {
        debugPrint('Exact alarm rejected, falling back to inexact: $exactError');
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: '⏰ ${task.title}',
          body: task.description?.isNotEmpty == true
              ? task.description
              : 'Scheduled for ${task.dueTime ?? task.dueDate} (${task.priority.toUpperCase()} priority)',
          scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails: _buildNotificationDetails(option),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        return true;
      }
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
      return false;
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }

  Future<bool> sendInstantNotification(String title, String body, {String? soundId}) async {
    try {
      final effectiveSoundId = soundId ?? await getSelectedSoundId();
      final option = getSoundOption(effectiveSoundId);

      await _notificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: title,
        body: body,
        notificationDetails: _buildNotificationDetails(option),
      );
      return true;
    } catch (e) {
      debugPrint('Error sending instant notification: $e');
      return false;
    }
  }

  Future<bool> previewSound(String soundId) async {
    try {
      final option = getSoundOption(soundId);
      await _notificationsPlugin.show(
        id: 99998,
        title: '🔔 Sound Preview: ${option.title}',
        body: 'Playing notification tone (${option.title})',
        notificationDetails: _buildNotificationDetails(option),
      );
      return true;
    } catch (e) {
      debugPrint('Error previewing sound: $e');
      return false;
    }
  }
}
