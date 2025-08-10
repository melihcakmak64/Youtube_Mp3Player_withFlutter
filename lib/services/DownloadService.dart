import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_downloader/core/StringExtensions.dart';

typedef ProgressCallback = void Function(double progress);

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
    required int totalBytes, // Toplam boyut burada lazım
    ProgressCallback? onProgress,
  }) async {
    final path = await getDownloadFolderPath();
    final file = File('$path/${fileName.sanitize()}.mp3');
    if (await file.exists()) {
      await file.delete();
    }
    final fileSink = file.openWrite();
    int downloadedBytes = 0;

    await for (final data in stream) {
      downloadedBytes += data.length;
      fileSink.add(data);

      if (totalBytes > 0) {
        final progress = downloadedBytes / totalBytes;
        onProgress?.call(progress.clamp(0.0, 1.0));
      } else {
        onProgress?.call(-1); // Toplam boyut bilinmiyor
      }
    }

    await fileSink.flush();
    await fileSink.close();

    return file;
  }

  /// Dosya mevcut mu kontrol eder
  Future<bool> fileExists(String fileName) async {
    final path = await getDownloadFolderPath();
    return File('$path/${fileName.sanitize()}.mp3').exists();
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
