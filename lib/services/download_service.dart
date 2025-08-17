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
    if (await tempMp4.exists()) await tempMp4.delete();

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

    // FFmpeg ile MP3'e dönüştür
    final mp3Path = '$path/$fileName.mp3';

    final mp3File = await VideoService.convertMp4ToMp3(
      inputPath: tempMp4.path,
      outputPath: mp3Path,
    );

    await tempMp4.delete(); // Geçici dosyayı temizle
    return mp3File;
  }

  /// Video ve audio stream’lerini indirip tek MP4 oluştur
  Future<File> downloadVideo({
    required Stream<List<int>> videoStream,
    required Stream<List<int>> audioStream,
    required String fileName,
    required int videoBytes,
    required int audioBytes,
    ProgressCallback? onProgress,
  }) async {
    final path = await getDownloadFolderPath();

    final tempVideo = File('$path/$fileName.temp_video.mp4');
    final tempAudio = File('$path/$fileName.temp_audio.mp4');
    final outputFile = File('$path/$fileName.mp4');

    if (await tempVideo.exists()) await tempVideo.delete();
    if (await tempAudio.exists()) await tempAudio.delete();
    if (await outputFile.exists()) await outputFile.delete();

    // Video indir
    int downloadedVideo = 0;
    final videoSink = tempVideo.openWrite();
    await for (final data in videoStream) {
      downloadedVideo += data.length;
      videoSink.add(data);
      if (videoBytes > 0) {
        onProgress?.call((downloadedVideo / videoBytes).clamp(0.0, 1.0));
      } else {
        onProgress?.call(-1);
      }
    }
    await videoSink.flush();
    await videoSink.close();

    // Audio indir
    int downloadedAudio = 0;
    final audioSink = tempAudio.openWrite();
    await for (final data in audioStream) {
      downloadedAudio += data.length;
      audioSink.add(data);
      if (audioBytes > 0) {
        onProgress?.call((downloadedAudio / audioBytes).clamp(0.0, 1.0));
      } else {
        onProgress?.call(-1);
      }
    }
    await audioSink.flush();
    await audioSink.close();

    // Video ve audio’yu birleştir
    final outputPath = '$path/$fileName.mp4';

    final mergedFile = await VideoService.mergeAudioVideo(
      videoPath: tempVideo.path,
      audioPath: tempAudio.path,
      outputPath: outputPath,
    );
    // Geçici dosyaları temizle
    await tempVideo.delete();
    await tempAudio.delete();
    return mergedFile;
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
