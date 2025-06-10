import 'package:flutter_local_notifications/flutter_local_notifications.dart';
class LocalNotificationService {

  // private constructor for singleton pattern
  LocalNotificationService._internal();

  // singleton instance
static final  LocalNotificationService  _instance = LocalNotificationService._internal();

// factory constructor to return singleton instance
factory LocalNotificationService.instance() => _instance;

// main plugin instance for handling notification
late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

// android specific initialization settings app launcher icon
final _androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');

// ios specific initialization settings with permission

final _iosInitializationSetting = const DarwinInitializationSettings(
  requestAlertPermission: true,
  requestBadgePermission: true,
  requestSoundPermission: true,
);

// android notification channel configuration
final _androidChannel = const AndroidNotificationChannel(
'channel_id', 'Channel name',description: 'Android push notification channel',
importance: Importance.max);
}