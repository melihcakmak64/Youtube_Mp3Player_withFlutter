import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:youtube_downloader/core/SharedPreferencesService.dart';
import 'package:youtube_downloader/services/DownloadService.dart';
import 'package:youtube_downloader/services/YoutubeExplodeService.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  final DownloadService downloadService = DownloadService();
  final YoutubeExplodeService youtubeService = YoutubeExplodeService();
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
      // final int totalBytes = data['totalBytes'];
      final int itag = data['itag'];

      final manifest = await youtubeService.youtube.videos.streamsClient
          .getManifest(url);
      final streamInfo = manifest.streams.firstWhere((s) => s.tag == itag);
      final stream = youtubeService.youtube.videos.streamsClient.get(
        streamInfo,
      );

      final String extension = streamInfo.container.name;
      final int totalBytes = streamInfo.size.totalBytes;

      final file = await downloadService.saveStream(
        stream: stream,
        fileName: fileName,
        extension: extension,
        totalBytes: totalBytes,
        onProgress: (progress) {
          // UI tarafına progress gönder
          FlutterForegroundTask.updateService(
            notificationTitle: 'Foreground Task',
            notificationText: '$progress',
          );
          FlutterForegroundTask.sendDataToMain({'progress': progress});
        },
      );

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
