import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static Future<void> addFile(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList(key) ?? [];
    if (!stringList.contains(value)) {
      stringList.add(value);
      await prefs.setStringList(key, stringList);
    }
  }

  static Future<void> removeFile(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList(key) ?? [];
    if (stringList.contains(value)) {
      stringList.remove(value);
      await prefs.setStringList(key, stringList);
    }
  }

  static Future<List<String>> getFiles(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }
}
