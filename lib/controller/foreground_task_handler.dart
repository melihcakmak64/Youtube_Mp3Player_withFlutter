import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:youtube_downloader/controller/foreground_service_manager.dart';
import 'package:youtube_downloader/core/SharedPreferencesService.dart';
import 'package:youtube_downloader/core/StringExtensions.dart';
import 'package:youtube_downloader/helper/helper.dart';
import 'package:youtube_downloader/services/DownloadService.dart';
import 'package:youtube_downloader/services/NotificationService.dart';
import 'package:youtube_downloader/services/YoutubeExplodeService.dart';

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
      final String extension = data['extension'];
      final String stream = data['stream'];
      final int totalBytes = data['totalBytes'];
      final convertedStream = stringToStream(stream);
      print("geldi");
      print(convertedStream);

      final file = await downloadService.saveStream(
        stream: convertedStream,
        fileName: fileName,
        extension: extension,
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
          });
        },
      );
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
