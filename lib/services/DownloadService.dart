import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  /// İndirilecek klasörün tam yolunu döner
  Future<String> getDownloadFolderPath() async {
    final directory = await getExternalStorageDirectory();
    final downloadPath =
        '${directory!.parent.parent.parent.parent.path}/Download/MusicFolder';
    await Directory(downloadPath).create(recursive: true);
    return downloadPath;
  }

  /// Stream'i mp3 dosyası olarak kaydeder
  Future<File> saveMusicStream({
    required Stream<List<int>> stream,
    required String fileName,
  }) async {
    final path = await getDownloadFolderPath();
    final file = File('$path/$fileName.mp3');
    final fileStream = file.openWrite();
    await stream.pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();
    return file;
  }

  /// Dosya mevcut mu kontrol eder
  Future<bool> fileExists(String fileName) async {
    final path = await getDownloadFolderPath();
    return File('$path/$fileName.mp3').exists();
  }

  /// Dosyayı siler
  Future<bool> deleteFile(String fileName) async {
    final path = await getDownloadFolderPath();
    final file = File('$path/$fileName.mp3');
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }
}
