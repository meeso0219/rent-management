import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:rent_management/models/lease.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> syncAllNotifications(List<Lease> leases) async {
    for (final lease in leases) {
      await syncFollowUpNotification(lease);
      await syncLeaseExpirationNotification(lease);
    }
  }

  Future<void> syncFollowUpNotification(Lease lease) async {
    final nextFollowUpDate = lease.nextFollowUpDate;
    if (nextFollowUpDate == null) {
      await cancelNotificationsByLeaseId(lease.id, followUpOnly: true);
      return;
    }

    final scheduledAt = DateTime(
      nextFollowUpDate.year,
      nextFollowUpDate.month,
      nextFollowUpDate.day,
      9,
    );

    if (!scheduledAt.isAfter(DateTime.now())) {
      await cancelNotificationsByLeaseId(lease.id, followUpOnly: true);
      return;
    }

    await _notifications.zonedSchedule(
      _followUpNotificationId(lease.id),
      'Follow-up reminder',
      '${lease.buildingName} ${lease.unitNumber} / ${lease.tenantName}',
      tz.TZDateTime.from(scheduledAt, tz.local),
      _notificationDetails(
        channelId: 'follow_up_notifications',
        channelName: 'Follow-up reminders',
        channelDescription: 'Reminds you to follow up with tenants.',
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> syncLeaseExpirationNotification(Lease lease) async {
    await cancelNotificationsByLeaseId(lease.id, expirationOnly: true);

    final sevenDaysBefore = DateTime(
      lease.leaseEnd.year,
      lease.leaseEnd.month,
      lease.leaseEnd.day - 7,
      9,
    );
    final onLeaseEnd = DateTime(
      lease.leaseEnd.year,
      lease.leaseEnd.month,
      lease.leaseEnd.day,
      9,
    );

    if (sevenDaysBefore.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        _expiringSoonNotificationId(lease.id),
        'Lease expires in 7 days',
        '${lease.buildingName} ${lease.unitNumber} lease is ending soon.',
        tz.TZDateTime.from(sevenDaysBefore, tz.local),
        _notificationDetails(
          channelId: 'lease_expiration_notifications',
          channelName: 'Lease expiration reminders',
          channelDescription: 'Reminds you about upcoming lease end dates.',
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    if (onLeaseEnd.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        _expiringTodayNotificationId(lease.id),
        'Lease expires today',
        '${lease.buildingName} ${lease.unitNumber} lease ends today.',
        tz.TZDateTime.from(onLeaseEnd, tz.local),
        _notificationDetails(
          channelId: 'lease_expiration_notifications',
          channelName: 'Lease expiration reminders',
          channelDescription: 'Reminds you about upcoming lease end dates.',
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelNotificationsByLeaseId(
    String leaseId, {
    bool followUpOnly = false,
    bool expirationOnly = false,
  }) async {
    if (!expirationOnly) {
      await _notifications.cancel(_followUpNotificationId(leaseId));
    }
    if (!followUpOnly) {
      await _notifications.cancel(_expiringSoonNotificationId(leaseId));
      await _notifications.cancel(_expiringTodayNotificationId(leaseId));
    }
  }

  NotificationDetails _notificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  int _followUpNotificationId(String leaseId) => leaseId.hashCode & 0x1fffffff;

  int _expiringSoonNotificationId(String leaseId) =>
      (leaseId.hashCode & 0x1fffffff) + 700000000;

  int _expiringTodayNotificationId(String leaseId) =>
      (leaseId.hashCode & 0x1fffffff) + 1400000000;

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }
}
