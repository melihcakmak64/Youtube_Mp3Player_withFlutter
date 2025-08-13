import 'dart:io';
import 'package:path_provider/path_provider.dart';

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

  /// Stream'i kaydeder ve tam dosya yolunu döner
  Future<File> saveStream({
    required Stream<List<int>> stream,
    required String fileName,
    required String extension, // mp3, mp4, webm vs.
    required int totalBytes,
    ProgressCallback? onProgress,
  }) async {
    final path = await getDownloadFolderPath();
    final file = File('$path/$fileName.$extension');

    if (await file.exists()) {
      await file.delete();
    }

    final fileSink = file.openWrite();
    int downloadedBytes = 0;

    await for (final data in stream) {
      downloadedBytes += data.length;
      fileSink.add(data);

      if (totalBytes > 0) {
        onProgress?.call((downloadedBytes / totalBytes).clamp(0.0, 1.0));
      } else {
        onProgress?.call(-1);
      }
    }

    await fileSink.flush();
    await fileSink.close();
    return file;
  }

  Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return file.exists();
  }

  Future<bool> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }
}
