import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_downloader/services/ffpmeg_service.dart';

typedef ProgressCallback = void Function(double progress);

class DownloadService {
  /// Ses dosyası indir ve MP3'e dönüştür
  Future<File> downloadAudio({
    required Stream<List<int>> stream,
    required String fileName,
    required int totalBytes,
    ProgressCallback? onProgress,
  }) async {
    final path = await getDownloadFolderPath();

    // Geçici MP4 dosyası
    final tempMp4 = File('$path/$fileName.temp_audio.mp4');
    final finalMp3 = File('$path/$fileName.mp3');

    if (await tempMp4.exists()) await tempMp4.delete();
    if (await finalMp3.exists()) await finalMp3.delete();

    // Dosyayı indir
    final fileSink = tempMp4.openWrite();
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
    onProgress?.call(1);

    // FFmpegService ile MP3'e dönüştür
    final success = await FFmpegService.convertMp4ToMp3(
      inputPath: tempMp4.path,
      outputPath: finalMp3.path,
    );

    if (success) {
      await tempMp4.delete(); // Geçici dosyayı temizle
      return finalMp3;
    } else {
      throw Exception("FFmpeg audio conversion failed!");
    }
  }

  /// Video dosyası indir (MP4 olarak kaydet)
  Future<File> downloadVideo({
    required Stream<List<int>> stream,
    required String fileName,
    required int totalBytes,
    ProgressCallback? onProgress,
  }) async {
    final path = await getDownloadFolderPath();
    final file = File('$path/$fileName.mp4');

    if (await file.exists()) await file.delete();

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
    onProgress?.call(1);

    return file;
  }

  Future<bool> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return file.exists();
  }

  /// İndirilecek klasörün tam yolunu döner
  Future<String> getDownloadFolderPath() async {
    final directory = await getExternalStorageDirectory();
    final downloadPath =
        '${directory!.parent.parent.parent.parent.path}/Download/MusicFolder';
    await Directory(downloadPath).create(recursive: true);
    return downloadPath;
  }
}
