import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationState extends ChangeNotifier {
  static const _kKeyEnabled = 'notif_enabled';

  bool _enabled = false;
  bool get enabled => _enabled;

  /// App start par call karo (e.g., provider create: () => NotificationState()..load())
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _enabled = sp.getBool(_kKeyEnabled) ?? false;

    // OS permission se sync: agar OS ne band ki hui hai to hum bhi OFF kar den
    await _syncWithOS();
    notifyListeners();
  }

  /// UI toggle
  Future<void> setEnabled(bool value) async {
    // No-op if same state
    if (value == _enabled) return;

    if (value) {
      // Android 13+ / iOS par runtime permission
      final status = await Permission.notification.request();

      if (status.isGranted || status.isLimited) {
        _enabled = true;

        // TODO: yahan FCM topic subscribe karein (e.g., ride-updates)
        // await FirebaseMessaging.instance.subscribeToTopic('ride-updates');

      } else {
        // Permission na mile to OFF rakho
        _enabled = false;

        // Agar user ne "Don't ask again" / permanently denied kiya
        if (status.isPermanentlyDenied) {
          // (optional) Directly app settings khol do
          await openAppSettings();
        }
      }
    } else {
      // User toggle se band kar raha hai
      _enabled = false;

      // TODO: unsubscribe from topics if needed
      // await FirebaseMessaging.instance.unsubscribeFromTopic('ride-updates');
    }

    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kKeyEnabled, _enabled);
    notifyListeners();
  }

  /// Public helper: jab app RESUMED aaye to isse call karke OS ke saath state sync kar sakte ho.
  Future<void> refreshFromOS() async {
    final changed = await _syncWithOS();
    if (changed) {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_kKeyEnabled, _enabled);
      notifyListeners();
    }
  }

  /// Returns true if local state changed after syncing with OS permission.
  Future<bool> _syncWithOS() async {
    if (_enabled) {
      final status = await Permission.notification.status;
      if (!status.isGranted && !status.isLimited) {
        _enabled = false; // OS ne band ki — hum bhi OFF
        return true;
      }
    }
    return false;
  }
}
