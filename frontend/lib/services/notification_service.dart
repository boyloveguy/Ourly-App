import "notification_service_stub.dart"
    if (dart.library.js) "notification_service_web.dart";

/// Quan ly thong bao man hinh (Web / Mobile System Notification)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final NotificationServiceImpl _impl = NotificationServiceImpl();

  /// Xin quyen hien thi thong bao
  static Future<bool> requestPermission() => _impl.requestPermission();

  /// Gui thong bao noi tren man hinh
  static void sendScreenNotification({
    required String title,
    required String body,
    String? icon,
  }) => _impl.sendScreenNotification(
    title: title,
    body: body,
    icon: icon,
  );
}
