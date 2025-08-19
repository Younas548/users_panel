class NotificationService {
  bool notificationsAllowed = false;
  void setAllowed(bool v) => notificationsAllowed = v;

  void showSnackPreview() {/* UI-only in widget layer */}
}
