import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../controller/service.dart';

class ResultPage extends StatefulWidget {
  final String searchTerm;

  const ResultPage({super.key, required this.searchTerm});
  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final DownloadController controller = Get.put(DownloadController());
  final ScrollController scrollController = ScrollController();
  bool isLoading = false;
  String currentVideoUrl = "";

  @override
  void initState() {
    controller.searchVideos(widget.searchTerm);
    scrollController.addListener(_scrollListener);
    super.initState();
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    controller.getList().clear();
    super.dispose();
  }

  void _scrollListener() {
    if (scrollController.position.maxScrollExtent ==
        scrollController.position.pixels) {
      controller.getNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
      ),
      body: Center(
        child: Obx(
          () {
            if (controller.getList().isEmpty) {
              return const CircularProgressIndicator();
            } else {
              return ListView.builder(
                controller: scrollController,
                itemCount: controller.getList().length,
                itemBuilder: (context, index) {
                  var video = controller.getList()[index];
                  return getCard(video);
                },
              );
            }
          },
        ),
      ),
    );
  }

  Card getCard(Video video) {
    final duration = video.duration;
    final hours = duration?.inHours ?? 0;
    final minutes = duration?.inMinutes.remainder(60) ?? 0;
    final seconds = duration?.inSeconds.remainder(60) ?? 0;

    final formattedDuration = hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        leading: FadeInImage.assetNetwork(
          placeholder:
              'assets/placeholder-image.png', // Path to your temporary placeholder image
          image: video.thumbnails.mediumResUrl,
          fit: BoxFit.cover,
        ),
        title: Text("${video.title} ($formattedDuration)"),
        trailing: Obx(() {
          return controller.currentUrl.value == video.url
              ? IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () {
                    controller.stop();
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    controller.play(video.url);
                  },
                );
        }),
      ),
    );
  }
}
