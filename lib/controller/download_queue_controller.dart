import 'dart:collection';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:youtube_downloader/core/SharedPreferencesService.dart';
import 'package:youtube_downloader/core/StringExtensions.dart';
import 'package:youtube_downloader/model/DownloadTask.dart';
import 'package:youtube_downloader/services/download_service.dart';
import 'package:youtube_downloader/services/notification_service.dart';
import 'package:youtube_downloader/services/youtube_explode_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadQueueManager {
  DownloadQueueManager._internal();
  static final DownloadQueueManager instance = DownloadQueueManager._internal();

  final Queue<DownloadTask> _queue = Queue();
  int _activeDownloads = 0;
  final int _maxConcurrent = 2;

  late DownloadService downloadService;
  late YoutubeExplodeService youtubeService;

  void init({
    required DownloadService downloadService,
    required YoutubeExplodeService youtubeService,
  }) {
    this.downloadService = downloadService;
    this.youtubeService = youtubeService;
  }

  void addTask(DownloadTask task) {
    _queue.add(task);
    _tryStartNext();
  }

  void _tryStartNext() {
    if (_activeDownloads >= _maxConcurrent || _queue.isEmpty) return;

    final task = _queue.removeFirst();
    _activeDownloads++;

    _startDownload(task).whenComplete(() {
      _activeDownloads--;
      _tryStartNext();
    });
  }

  Future<void> _startDownload(DownloadTask task) async {
    final manifest = await youtubeService.youtube.videos.streamsClient
        .getManifest(task.url);

    final stream = manifest.streams.firstWhere((s) => s.tag == task.itag);

    if (stream is VideoOnlyStreamInfo) {
      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      final videoStreamInfo = stream;

      final videoStream = youtubeService.youtube.videos.streamsClient.get(
        videoStreamInfo,
      );
      final audioStream = youtubeService.youtube.videos.streamsClient.get(
        audioStreamInfo,
      );

      final totalVideoBytes = videoStreamInfo.size.totalBytes;
      final totalAudioBytes = audioStreamInfo.size.totalBytes;

      final finalFile = await downloadService.downloadVideo(
        videoStream: videoStream,
        audioStream: audioStream,
        fileName: task.fileName,
        videoBytes: totalVideoBytes,
        audioBytes: totalAudioBytes,
        onProgress: (progress) async {
          NotificationService.showDownloadProgress(
            id: task.url.hashCode,
            title: task.fileName.sanitize(),
            progress: (progress * 100).toInt(),
          );
          FlutterForegroundTask.sendDataToMain({
            'url': task.url,
            'progress': progress,
            'status': "downloading",
          });
        },
      );

      NotificationService.showDownloadProgress(
        id: task.url.hashCode,
        title: task.fileName.sanitize(),
        progress: 100,
      );

      FlutterForegroundTask.sendDataToMain({
        'url': task.url,
        'status': 'done',
        'path': finalFile.path,
      });

      await SharedPreferencesService.addFile('downloadedVideos', {
        'url': task.url,
        'extension': "mp4",
        'title': task.fileName,
        'path': finalFile.path,
      });
    } else {
      // Sadece ses indir
      final audioStream = youtubeService.youtube.videos.streamsClient.get(
        stream,
      );
      final totalAudioBytes = stream.size.totalBytes;

      final finalFile = await downloadService.downloadAudio(
        stream: audioStream,
        fileName: task.fileName,
        totalBytes: totalAudioBytes,
        onProgress: (progress) async {
          NotificationService.showDownloadProgress(
            id: task.url.hashCode,
            title: task.fileName.sanitize(),
            progress: (progress * 100).toInt(),
          );
          FlutterForegroundTask.sendDataToMain({
            'url': task.url,
            'progress': progress,
            'status': "downloading",
          });
        },
      );

      NotificationService.showDownloadProgress(
        id: task.url.hashCode,
        title: task.fileName.sanitize(),
        progress: 100,
      );

      FlutterForegroundTask.sendDataToMain({
        'url': task.url,
        'status': 'done',
        'path': finalFile.path,
      });

      await SharedPreferencesService.addFile('downloadedAudios', {
        'url': task.url,
        'extension': "mp3",
        'title': task.fileName,
        'path': finalFile.path,
      });
    }
  }
}
