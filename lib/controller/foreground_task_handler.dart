import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:youtube_downloader/controller/download_queue_controller.dart';
import 'package:youtube_downloader/model/DownloadTask.dart';
import 'package:youtube_downloader/services/download_service.dart';
import 'package:youtube_downloader/services/youtube_explode_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    DownloadQueueManager.instance.init(
      downloadService: DownloadService(
        youtubeExplodeService: YoutubeExplodeService(),
      ),
    );
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

      DownloadQueueManager.instance.addTask(
        DownloadTask(url: url, fileName: fileName, itag: itag),
      );
    }
  }

  @override
  void onNotificationButtonPressed(String id) {}
  @override
  void onNotificationPressed() {}
  @override
  void onNotificationDismissed() {}
}
