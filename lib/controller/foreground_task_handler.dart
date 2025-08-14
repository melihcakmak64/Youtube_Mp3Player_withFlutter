import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  static const String incrementCountCommand = 'incrementCount';
  int _count = 0;

  void _incrementCount() {
    _count++;
    FlutterForegroundTask.updateService(
      notificationTitle: 'Foreground Task',
      notificationText: 'count: $_count',
    );
    FlutterForegroundTask.sendDataToMain(_count);
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _incrementCount();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _incrementCount();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    if (data == incrementCountCommand) _incrementCount();
  }

  @override
  void onNotificationButtonPressed(String id) {}
  @override
  void onNotificationPressed() {}
  @override
  void onNotificationDismissed() {}
}
