import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static Future<void> addFile(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedVideos = prefs.getStringList(key) ?? [];
    if (!downloadedVideos.contains(value)) {
      downloadedVideos.add(value);
      await prefs.setStringList(key, downloadedVideos);
    }
  }

  static Future<void> removeFile(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedVideos = prefs.getStringList(key) ?? [];
    if (downloadedVideos.contains(value)) {
      downloadedVideos.remove(value);
      await prefs.setStringList(key, downloadedVideos);
    }
  }

  static Future<List<String>> getFiles(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }
}
