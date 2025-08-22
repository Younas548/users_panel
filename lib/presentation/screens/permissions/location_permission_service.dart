import 'package:geolocator/geolocator.dart';

/// App-wide enum for location permission state
enum LocPerm { granted, denied, permanentlyDenied, serviceDisabled }

/// Single source of truth for checking/requesting location permission
class LocationPermissionService {
  /// Check current status (also checks whether GPS/service is enabled)
  static Future<LocPerm> check() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocPerm.serviceDisabled;

    final perm = await Geolocator.checkPermission();
    switch (perm) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocPerm.granted;
      case LocationPermission.denied:
        return LocPerm.denied;
      case LocationPermission.deniedForever:
        return LocPerm.permanentlyDenied;
      default:
        return LocPerm.denied;
    }
  }

  /// Request permission (and short-circuit if service/GPS is OFF)
  static Future<LocPerm> request() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocPerm.serviceDisabled;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    switch (perm) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocPerm.granted;
      case LocationPermission.denied:
        return LocPerm.denied;
      case LocationPermission.deniedForever:
        return LocPerm.permanentlyDenied;
      default:
        return LocPerm.denied;
    }
  }

  /// Helpers to open OS settings
  static Future<void> openLocationSettings() => Geolocator.openLocationSettings();
  static Future<void> openAppSettings() => Geolocator.openAppSettings();
}
