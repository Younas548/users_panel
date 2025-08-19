import 'package:flutter/material.dart';

enum PermissionStatus { unknown, allowed, denied }

class PermissionState extends ChangeNotifier {
  PermissionStatus location = PermissionStatus.unknown;
  PermissionStatus notifications = PermissionStatus.unknown;

  void setLocation(PermissionStatus s) { location = s; notifyListeners(); }
  void setNotifications(PermissionStatus s) { notifications = s; notifyListeners(); }

  bool get allGood => location == PermissionStatus.allowed && notifications == PermissionStatus.allowed;
}
