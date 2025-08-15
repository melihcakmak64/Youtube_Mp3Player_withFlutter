import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/controller/foreground_service_manager.dart';
import 'package:youtube_downloader/view/counterProvider.dart';

class ExamplePage extends ConsumerStatefulWidget {
  const ExamplePage({super.key});

  @override
  ConsumerState<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends ConsumerState<ExamplePage> {
  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ForegroundServiceManager.init();
    });
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }

  void _onReceiveTaskData(Object data) {
    if (data is int) {
      ref.read(counterProvider.notifier).updateFromTask(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(counterProvider);

    return WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(title: const Text('Flutter Foreground Task')),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Data from TaskHandler:'),
                      Text(
                        '$count',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: ForegroundServiceManager.start,
                      child: const Text('Start Service'),
                    ),
                    ElevatedButton(
                      onPressed: ForegroundServiceManager.stop,
                      child: const Text('Stop Service'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(counterProvider.notifier).increment(),
                      child: const Text('Increment Count'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
