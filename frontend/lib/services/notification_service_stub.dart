import "package:flutter/foundation.dart";

class NotificationServiceImpl {
  Future<bool> requestPermission() async => true;

  void sendScreenNotification({
    required String title,
    required String body,
    String? icon,
  }) {
    debugPrint("[NotificationService] (Stub/Mobile) $title: $body");
  }
}
