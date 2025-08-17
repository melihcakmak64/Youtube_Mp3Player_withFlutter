import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:youtube_downloader/core/SharedPreferencesService.dart';
import 'package:youtube_downloader/core/StringExtensions.dart';
import 'package:youtube_downloader/services/download_service.dart';
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
      final isVideo = true;

      final audioStreamInfo = isVideo
          ? manifest.audioOnly.withHighestBitrate()
          : manifest.streams.firstWhere((s) => s.tag == itag);
      final videoStreamInfo = manifest.streams.firstWhere((s) => s.tag == itag);

      if (videoStreamInfo == null && audioStreamInfo == null) return;

      late final File finalFile;

      if (videoStreamInfo != null) {
        // Video-only varsa, audio ile birleştir
        final videoStream = youtubeService.youtube.videos.streamsClient.get(
          videoStreamInfo,
        );
        Stream<List<int>>? audioStream;

        if (audioStreamInfo != null) {
          audioStream = youtubeService.youtube.videos.streamsClient.get(
            audioStreamInfo,
          );
        }

        final totalVideoBytes = videoStreamInfo.size.totalBytes;
        final totalAudioBytes = audioStreamInfo?.size.totalBytes ?? 0;

        finalFile = await downloadService.downloadVideo(
          videoStream: videoStream,
          audioStream: audioStream ?? Stream.empty(),
          fileName: fileName,
          videoBytes: totalVideoBytes,
          audioBytes: totalAudioBytes,
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
      } else if (audioStreamInfo != null) {
        // Sadece audio varsa MP3 indir
        final audioStream = youtubeService.youtube.videos.streamsClient.get(
          audioStreamInfo,
        );
        final totalAudioBytes = audioStreamInfo.size.totalBytes;

        finalFile = await downloadService.downloadAudio(
          stream: audioStream,
          fileName: fileName,
          totalBytes: totalAudioBytes,
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
        'path': finalFile.path,
      });

      await SharedPreferencesService.addFile('downloadedVideos', {
        'url': url,
        'extension': "mp4",
        'title': fileName,
        'path': finalFile.path,
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
