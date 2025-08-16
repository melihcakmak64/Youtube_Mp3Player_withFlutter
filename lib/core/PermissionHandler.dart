import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  /// Tüm gerekli izinleri kontrol eder ve gerekirse kullanıcıya sorar.
  static Future<void> ensurePermissions() async {
    DeviceInfoPlugin plugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo android = await plugin.androidInfo;

      // Android 11 ve sonrası
      if (android.version.sdkInt >= 30) {
        if (!await Permission.manageExternalStorage.isGranted) {
          await Permission.manageExternalStorage.request();
        }
      } else {
        // Android 10 ve altı
        if (!await Permission.storage.isGranted) {
          await Permission.storage.request();
        } else if (await Permission.storage.isPermanentlyDenied) {
          await openAppSettings();
        }
      }

      // Android 13 ve sonrası için audio ve notification izinleri
      if (android.version.sdkInt >= 33) {
        if (!await Permission.audio.isGranted) {
          await Permission.audio.request();
        } else if (await Permission.audio.isPermanentlyDenied) {
          await openAppSettings();
        }

        if (!await Permission.notification.isGranted) {
          await Permission.notification.request();
        }
      }

      // FlutterForegroundTask izinleri
      if (await FlutterForegroundTask.checkNotificationPermission() !=
          NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      if (!await FlutterForegroundTask.canScheduleExactAlarms) {
        await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      }
    } else if (Platform.isIOS) {
      // iOS için sadece notification izinleri
      if (!await Permission.notification.isGranted) {
        await Permission.notification.request();
      }
    }
  }
}
