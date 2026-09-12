// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import "dart:html" as html;
import "package:flutter/foundation.dart";

class NotificationServiceImpl {
  bool _hasRequestedPermission = false;

  Future<bool> requestPermission() async {
    try {
      if (html.Notification.supported) {
        final permission = await html.Notification.requestPermission();
        _hasRequestedPermission = true;
        return permission == "granted";
      }
    } catch (e) {
      debugPrint("[NotificationService] Permission request error: $e");
    }
    return false;
  }

  void sendScreenNotification({
    required String title,
    required String body,
    String? icon,
  }) {
    try {
      if (html.Notification.supported) {
        if (html.Notification.permission == "granted") {
          html.Notification(
            title,
            body: body,
            icon: icon ?? "assets/images/spot_bistro.jpg",
          );
        } else if (!_hasRequestedPermission) {
          requestPermission().then((granted) {
            if (granted) {
              html.Notification(
                title,
                body: body,
                icon: icon ?? "assets/images/spot_bistro.jpg",
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint("[NotificationService] Notification error: $e");
    }
  }
}
