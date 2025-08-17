import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:youtube_downloader/core/SharedPreferencesService.dart';
import 'package:youtube_downloader/core/StringExtensions.dart';
import 'package:youtube_downloader/services/download_service.dart';
import 'package:youtube_downloader/services/ffpmeg_service.dart';
import 'package:youtube_downloader/services/notification_service.dart';
import 'package:youtube_downloader/services/youtube_explode_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(
    MyTaskHandler(
      downloadService: DownloadService(),
      youtubeService: YoutubeExplodeService(),
    ),
  );
}

class MyTaskHandler extends TaskHandler {
  final DownloadService downloadService;
  final YoutubeExplodeService youtubeService;
  MyTaskHandler({required this.downloadService, required this.youtubeService});

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    FlutterForegroundTask.updateService(
      notificationTitle: 'Foreground Task',
      notificationText: 'service started',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) async {
    if (data is Map && data['action'] == 'download') {
      final String url = data['url'];
      final String fileName = data['fileName'];
      final int itag = data['itag'];
      final manifest = await youtubeService.youtube.videos.streamsClient
          .getManifest(url);
      final streamInfo = manifest.streams.firstWhere((s) => s.tag == itag);
      final stream = youtubeService.youtube.videos.streamsClient.get(
        streamInfo,
      );

      final String extension = streamInfo.container.name;
      final int totalBytes = streamInfo.size.totalBytes;

      File file;

      // 🔹 Audio mu Video mu kontrol et
      if (streamInfo is AudioOnlyStreamInfo) {
        file = await downloadService.downloadAudio(
          stream: stream,
          fileName: fileName,
          totalBytes: totalBytes,
          onProgress: (progress) async {
            NotificationService.showDownloadProgress(
              id: url.hashCode,
              title: fileName.sanitize(),
              progress: (progress * 100).toInt(),
            );
            FlutterForegroundTask.sendDataToMain({
              'url': url,
              'progress': progress,
              'status': "downloading",
            });
          },
        );
      } else {
        file = await downloadService.downloadVideo(
          stream: stream,
          fileName: fileName,
          totalBytes: totalBytes,
          onProgress: (progress) async {
            NotificationService.showDownloadProgress(
              id: url.hashCode,
              title: fileName.sanitize(),
              progress: (progress * 100).toInt(),
            );
            FlutterForegroundTask.sendDataToMain({
              'url': url,
              'progress': progress,
              'status': "downloading",
            });
          },
        );
      }

      NotificationService.showDownloadProgress(
        id: url.hashCode,
        title: fileName.sanitize(),
        progress: 100,
      );

      FlutterForegroundTask.sendDataToMain({
        'url': url,
        'status': 'done',
        'path': file.path,
      });

      await SharedPreferencesService.addFile('downloadedVideos', {
        'url': url,
        'extension': extension,
        'title': fileName,
        'path': file.path,
      });
    }
  }

  @override
  void onNotificationButtonPressed(String id) {}
  @override
  void onNotificationPressed() {}
  @override
  void onNotificationDismissed() {}
}
