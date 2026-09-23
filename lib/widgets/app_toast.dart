import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ToastType { success, info, error, warning }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();

    Color iconColor;
    IconData defaultIcon;

    switch (type) {
      case ToastType.success:
        iconColor = AppTheme.accentGreen;
        defaultIcon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        iconColor = AppTheme.accentCoral;
        defaultIcon = Icons.error_rounded;
        break;
      case ToastType.warning:
        iconColor = AppTheme.accentAmber;
        defaultIcon = Icons.warning_rounded;
        break;
      case ToastType.info:
        iconColor = AppTheme.primary;
        defaultIcon = Icons.info_outline_rounded;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceBorder, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon ?? defaultIcon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void success(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context,
      message: message,
      type: ToastType.success,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: ToastType.error,
      icon: icon,
      duration: duration,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context,
      message: message,
      type: ToastType.info,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: ToastType.warning,
      icon: icon,
      duration: duration,
    );
  }
}
