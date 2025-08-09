import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_downloader/view/widgets/musicCard.dart';
import 'package:youtube_downloader/view/widgets/slider.dart';
import '../controller/DownloadController.dart';

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
    if (controller.currentVideo.value != null) {
      controller.stop(controller.currentVideo.value!);
    }

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
      appBar: AppBar(title: const Text('Results')),
      body: Stack(
        children: [
          Center(
            child: Obx(() {
              if (controller.getList().isEmpty) {
                return const CircularProgressIndicator();
              } else {
                return ListView.builder(
                  controller: scrollController,
                  itemCount: controller.getList().length,
                  itemBuilder: (context, index) {
                    var video = controller.getList()[index];
                    return MusicCard(controller: controller, video: video);
                  },
                );
              }
            }),
          ),
          MusicSlider(controller: controller),
        ],
      ),
    );
  }
}
