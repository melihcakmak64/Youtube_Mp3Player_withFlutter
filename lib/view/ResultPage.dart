import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/controller/DownloadController.dart';
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
    // Arama işlemini başlat
    ref.read(downloadProvider.notifier).searchVideos(widget.searchTerm);

    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (scrollController.position.maxScrollExtent ==
        scrollController.position.pixels) {
      ref.read(downloadProvider.notifier).getNextPage();
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    // Eğer çalan müzik varsa durdur
    final currentVideo = ref.read(downloadProvider).currentVideo;
    if (currentVideo != null) {
      ref.read(downloadProvider.notifier).stop(currentVideo);
    }
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoList = ref.watch(downloadProvider).videoList;

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: videoList.isEmpty
                  ? const CircularProgressIndicator()
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: videoList.length,
                      itemBuilder: (context, index) {
                        final video = videoList[index];
                        return MusicCard(
                          key: ValueKey(video.model.id),
                          video: video,
                        );
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
