import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/security_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'pin_lock_screen.dart';

class PrivacyScreen extends StatefulWidget {
  final VoidCallback? onLockStateChanged;

  const PrivacyScreen({super.key, this.onLockStateChanged});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _isLockEnabled = false;
  int _timeoutSeconds = 0;
  Map<String, int> _dbStats = {'tasks': 0, 'notes': 0};
  bool _isLoading = true;
  String _selectedSoundId = 'default';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final enabled = await SecurityService.instance.isLockEnabled();
    final timeout = await SecurityService.instance.getAutoLockTimeout();
    final stats = await DatabaseService.instance.getDatabaseStats();
    final soundId = await NotificationService.instance.getSelectedSoundId();

    setState(() {
      _isLockEnabled = enabled;
      _timeoutSeconds = timeout;
      _dbStats = stats;
      _selectedSoundId = soundId;
      _isLoading = false;
    });
  }

  Future<void> _toggleLock(bool value) async {
    if (value) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const PinLockScreen(mode: PinMode.setup),
        ),
      );
      if (result == true) {
        _loadSettings();
        widget.onLockStateChanged?.call();
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Disable Passcode?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          content: const Text(
            'Anyone with access to your phone will be able to view your daily tasks and notes without a PIN.',
            style: TextStyle(color: Color(0xFF3C3C43), fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Disable',
                style: TextStyle(
                  color: AppTheme.accentCoral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await SecurityService.instance.disableLock();
        _loadSettings();
        widget.onLockStateChanged?.call();
      }
    }
  }

  Future<void> _changePin() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const PinLockScreen(mode: PinMode.change),
      ),
    );
    if (result == true) {
      _loadSettings();
    }
  }

  Future<void> _changeTimeout(int seconds) async {
    await SecurityService.instance.setAutoLockTimeout(seconds);
    setState(() => _timeoutSeconds = seconds);
  }

  Future<void> _onSelectSound(String soundId) async {
    try {
      await NotificationService.instance.setSelectedSoundId(soundId);
      setState(() => _selectedSoundId = soundId);
      await NotificationService.instance.previewSound(soundId);
      if (mounted) {
        final option = NotificationService.instance.getSoundOption(soundId);
        AppToast.info(
          context,
          'Selected "${option.title}" tone',
          icon: option.icon,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Could not play sound: $e');
      }
    }
  }

  Future<void> _previewSound(String soundId) async {
    try {
      await NotificationService.instance.previewSound(soundId);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Preview error: $e');
      }
    }
  }

  Future<void> _testNotification() async {
    try {
      final option = NotificationService.instance.getSoundOption(
        _selectedSoundId,
      );
      final success = await NotificationService.instance
          .sendInstantNotification(
            'DailyTask Local Alarm',
            'Test successful! Playing ${option.title} without internet.',
          );
      if (mounted) {
        if (success) {
          AppToast.success(
            context,
            'Test notification sent with "${option.title}"!',
            icon: Icons.notifications_active_rounded,
          );
        } else {
          AppToast.warning(
            context,
            'Please allow Notifications in phone Settings > Apps > DailyTask',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Notification error: $e');
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete All Local Data?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: const Text(
          'This will permanently delete all your tasks and notes stored on this device. This action cannot be undone.',
          style: TextStyle(color: Color(0xFF3C3C43), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete Everything',
              style: TextStyle(
                color: AppTheme.accentCoral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.instance.clearAllData();
      await NotificationService.instance.cancelAllNotifications();
      _loadSettings();
      if (mounted) {
        AppToast.info(
          context,
          'All local data has been erased.',
          icon: Icons.delete_sweep_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.groupedBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.groupedBackground,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.8,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // App Lock Section (Apple Settings Inset Grouped)
                _buildSectionHeader('PASSCODE & SECURITY'),
                const SizedBox(height: 8),
                _buildInsetGroup([
                  _buildSettingsRow(
                    iconBg: AppTheme.primary,
                    icon: Icons.lock_rounded,
                    title: 'Passcode Lock',
                    trailing: Switch.adaptive(
                      value: _isLockEnabled,
                      activeTrackColor: AppTheme.accentGreen,
                      onChanged: _toggleLock,
                    ),
                  ),
                  if (_isLockEnabled) ...[
                    _buildHairlineDivider(),
                    _buildSettingsRow(
                      iconBg: AppTheme.accentIndigo,
                      icon: Icons.key_rounded,
                      title: 'Change 4-Digit Passcode',
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      onTap: _changePin,
                    ),
                    _buildHairlineDivider(),
                    _buildSettingsRow(
                      iconBg: AppTheme.accentAmber,
                      icon: Icons.timer_rounded,
                      title: 'Auto-Lock',
                      trailing: DropdownButton<int>(
                        value: _timeoutSeconds,
                        dropdownColor: Colors.white,
                        underline: const SizedBox(),
                        icon: const Icon(
                          Icons.unfold_more_rounded,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 0,
                            child: Text('Immediately'),
                          ),
                          DropdownMenuItem(value: 60, child: Text('1 minute')),
                          DropdownMenuItem(
                            value: 300,
                            child: Text('5 minutes'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) _changeTimeout(val);
                        },
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 22),

                // Offline Notifications & Sound Section
                _buildSectionHeader('NOTIFICATION SOUND'),
                const SizedBox(height: 8),
                _buildInsetGroup([
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        _buildSettingIcon(
                          AppTheme.accentBlue,
                          Icons.volume_up_rounded,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Tone',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            NotificationService.instance
                                .getSoundOption(_selectedSoundId)
                                .title,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildHairlineDivider(),
                  ...NotificationService.soundOptions.map((opt) {
                    final isSelected = _selectedSoundId == opt.id;
                    return InkWell(
                      onTap: () => _onSelectSound(opt.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.05)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 42,
                            ), // Indent to align with text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        opt.title,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? AppTheme.primary
                                              : AppTheme.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (opt.id == 'default') ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentGreen
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Text(
                                            'Default',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.accentGreen,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    opt.description,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_circle_fill_rounded),
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              iconSize: 24,
                              tooltip: 'Preview',
                              onPressed: () => _previewSound(opt.id),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  _buildHairlineDivider(),
                  _buildSettingsRow(
                    iconBg: AppTheme.accentPurple,
                    icon: Icons.notifications_active_rounded,
                    title: 'Test Notification Tone',
                    subtitle:
                        'Sends test alarm with "${NotificationService.instance.getSoundOption(_selectedSoundId).title}"',
                    trailing: TextButton(
                      onPressed: _testNotification,
                      child: const Text(
                        'Test',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 22),

                // Local Database & Data Storage Section
                _buildSectionHeader('ON-DEVICE DATA & STORAGE'),
                const SizedBox(height: 8),
                _buildInsetGroup([
                  _buildSettingsRow(
                    iconBg: AppTheme.accentGreen,
                    icon: Icons.checklist_rounded,
                    title: 'Stored Tasks',
                    trailing: Text(
                      '${_dbStats['tasks']} items',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _buildHairlineDivider(),
                  _buildSettingsRow(
                    iconBg: AppTheme.accentAmber,
                    icon: Icons.sticky_note_2_rounded,
                    title: 'Stored Notes',
                    trailing: Text(
                      '${_dbStats['notes']} items',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _buildHairlineDivider(),
                  _buildSettingsRow(
                    iconBg: AppTheme.accentCoral,
                    icon: Icons.delete_forever_rounded,
                    title: 'Erase All Local Data',
                    subtitle: 'Wipe SQLite database and reset app state',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    onTap: _clearAllData,
                  ),
                ]),
                const SizedBox(height: 24),

                // About & App Version Section
                _buildSectionHeader('ABOUT'),
                const SizedBox(height: 8),
                _buildInsetGroup([
                  _buildSettingsRow(
                    iconBg: AppTheme.primary,
                    icon: Icons.info_outline_rounded,
                    title: 'Version',
                    trailing: const Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _buildHairlineDivider(),
                  _buildSettingsRow(
                    iconBg: AppTheme.accentGreen,
                    icon: Icons.lock_outline_rounded,
                    title: 'Data Privacy',
                    trailing: const Text(
                      '100% Offline',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentGreen,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _buildHairlineDivider(),
                  _buildSettingsRow(
                    iconBg: AppTheme.accentIndigo,
                    icon: Icons.verified_user_outlined,
                    title: 'Developer',
                    trailing: const Text(
                      'Mobintix Infotech',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ]),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildInsetGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingIcon(Color bg, IconData icon) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _buildSettingsRow({
    required Color iconBg,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildSettingIcon(iconBg, icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildHairlineDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 58),
      child: Divider(height: 1, thickness: 0.8, color: AppTheme.surfaceBorder),
    );
  }
}
