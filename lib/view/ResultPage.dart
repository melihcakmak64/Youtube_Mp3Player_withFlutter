import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/controller/VideoListController.dart';
import 'package:youtube_downloader/controller/foreground_service_manager.dart';
import 'package:youtube_downloader/view/widgets/MusicCard.dart';
import 'package:youtube_downloader/view/widgets/Slider.dart';

class ResultPage extends ConsumerStatefulWidget {
  final String searchTerm;

  const ResultPage({super.key, required this.searchTerm});

  @override
  ConsumerState<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends ConsumerState<ResultPage> {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref
          .read(videoListControllerProvider.notifier)
          .searchVideos(widget.searchTerm);
      ref.read(downloadControllerProvider.notifier).startForegroundTask();
    });

    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (scrollController.position.maxScrollExtent ==
        scrollController.position.pixels) {
      //ref.read(videoListControllerProvider.notifier).getNextPage();
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    // ref.read(downloadControllerProvider.notifier).disposeForegroundTask();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoList = ref.watch(videoListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: videoList.isLoading
                  ? const CircularProgressIndicator()
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: videoList.videos.length,
                      itemBuilder: (context, index) {
                        final video = videoList.videos[index];
                        return MusicCard(key: ValueKey(video.id), video: video);
                      },
                    ),
            ),
            MusicSlider(),
          ],
        ),
      ),
    );
  }
}
