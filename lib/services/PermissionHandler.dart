import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  static Future<void> chekPermission() async {
    DeviceInfoPlugin plugin = DeviceInfoPlugin();
    AndroidDeviceInfo android = await plugin.androidInfo;

    if (android.version.sdkInt < 33) {
      if (!(await Permission.storage.isGranted)) {
        await Permission.storage.request();
      } else if (await Permission.storage.isPermanentlyDenied) {
        openAppSettings();
      }
    } else {
      if (!(await Permission.audio.isGranted)) {
        await Permission.audio.request();
      } else if ((await Permission.audio.isPermanentlyDenied)) {
        openAppSettings();
      }
    }
  }
}
