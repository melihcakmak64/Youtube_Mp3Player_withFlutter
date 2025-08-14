// Riverpod StateNotifier ile sayaç
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/controller/foreground_task_handler.dart';

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);

  void increment() {
    state++;
    FlutterForegroundTask.sendDataToTask(MyTaskHandler.incrementCountCommand);
  }

  void updateFromTask(int value) => state = value;
}

// Provider
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});
