import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  /// Yeni dosya ekler veya mevcut olanın üzerine yazar
  static Future<void> addFile(String key, Map<String, dynamic> fileData) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList(key) ?? [];

    // Eğer aynı URL varsa, indeksini bulup üzerine yaz
    final index = stringList.indexWhere((item) {
      final map = jsonDecode(item);
      return map['url'] == fileData['url'];
    });

    final encoded = jsonEncode(fileData);

    if (index >= 0) {
      stringList[index] = encoded; // mevcut kaydın üzerine yaz
    } else {
      stringList.add(encoded); // yeni kayıt ekle
    }

    await prefs.setStringList(key, stringList);
  }

  /// Belirtilen URL’ye sahip dosyayı siler
  static Future<void> removeFile(String key, String url) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList(key) ?? [];

    stringList.removeWhere((item) {
      final map = jsonDecode(item);
      return map['url'] == url;
    });

    await prefs.setStringList(key, stringList);
  }

  /// Kayıtlı tüm dosyaları Map listesi olarak döner
  static Future<List<Map<String, dynamic>>> getFiles(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList(key) ?? [];

    return stringList.map((item) {
      return Map<String, dynamic>.from(jsonDecode(item));
    }).toList();
  }

  /// Tüm kayıtları temizler
  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
