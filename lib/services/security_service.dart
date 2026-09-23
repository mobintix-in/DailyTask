import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static final SecurityService instance = SecurityService._init();
  SecurityService._init();

  static const String _keyIsLockEnabled = 'app_lock_enabled';
  static const String _keyPinHash = 'app_lock_pin_hash';
  static const String _keyAutoLockTimeout = 'app_lock_timeout_seconds';
  static const String _keyLastPaused = 'app_lock_last_paused';

  static const String _salt = 'DailyTask_Local_Salt_2026_Privacy';

  bool _isUnlockedForSession = false;

  bool get isUnlockedForSession => _isUnlockedForSession;

  void markUnlocked() {
    _isUnlockedForSession = true;
  }

  void markLocked() {
    _isUnlockedForSession = false;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode('$_salt:$pin');
    return sha256.convert(bytes).toString();
  }

  Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLockEnabled) ?? false;
  }

  Future<bool> hasPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    final hash = prefs.getString(_keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  Future<bool> setPin(String pin) async {
    if (pin.length != 4) return false;
    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPin(pin);
    await prefs.setString(_keyPinHash, hash);
    await prefs.setBool(_keyIsLockEnabled, true);
    _isUnlockedForSession = true;
    return true;
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedHash = prefs.getString(_keyPinHash);
    if (savedHash == null) return false;
    final isValid = _hashPin(pin) == savedHash;
    if (isValid) {
      _isUnlockedForSession = true;
    }
    return isValid;
  }

  Future<void> disableLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLockEnabled, false);
    await prefs.remove(_keyPinHash);
    _isUnlockedForSession = false;
  }

  Future<int> getAutoLockTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAutoLockTimeout) ?? 0; // default 0: immediately
  }

  Future<void> setAutoLockTimeout(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoLockTimeout, seconds);
  }

  Future<void> recordPauseTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastPaused, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> shouldLockOnResume() async {
    final enabled = await isLockEnabled();
    if (!enabled) return false;

    final timeout = await getAutoLockTimeout();
    if (timeout == 0) {
      _isUnlockedForSession = false;
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastPaused = prefs.getInt(_keyLastPaused) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedSeconds = (now - lastPaused) ~/ 1000;

    if (elapsedSeconds >= timeout) {
      _isUnlockedForSession = false;
      return true;
    }

    return !_isUnlockedForSession;
  }
}
