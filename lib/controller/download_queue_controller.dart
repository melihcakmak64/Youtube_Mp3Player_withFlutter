import 'dart:collection';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:youtube_downloader/core/StringExtensions.dart';
import 'package:youtube_downloader/model/DownloadTask.dart';
import 'package:youtube_downloader/services/download_service.dart';
import 'package:youtube_downloader/services/foreground_service_manager.dart';
import 'package:youtube_downloader/services/notification_service.dart';

class DownloadQueueManager {
  DownloadQueueManager._internal();
  static final DownloadQueueManager instance = DownloadQueueManager._internal();

  final Queue<DownloadTask> _queue = Queue();
  int _activeDownloads = 0;
  final int _maxConcurrent = 2;

  late DownloadService downloadService;

  void init({required DownloadService downloadService}) {
    this.downloadService = downloadService;
  }

  void addTask(DownloadTask task) {
    _queue.add(task);
    _tryStartNext();
  }

  void _tryStartNext() {
    if (_activeDownloads >= _maxConcurrent) return;
    if (_activeDownloads == 0 && _queue.isEmpty) {
      ForegroundServiceManager.stop();
      return;
    }

    final task = _queue.removeFirst();
    _activeDownloads++;

    _startDownload(task).whenComplete(() {
      _activeDownloads--;
      _tryStartNext();
    });
  }

  Future<void> _startDownload(DownloadTask task) async {
    final finalFile = await downloadService.download(
      downloadTask: task,
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
  }
}
