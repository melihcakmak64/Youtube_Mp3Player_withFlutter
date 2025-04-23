import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_downloader/controller/DownloadController.dart';
import 'package:youtube_downloader/model/newModel.dart';

class MusicCard extends StatelessWidget {
  final ExtendedVideo video;
  final DownloadController
  controller; // Assuming you have a controller to manage play, stop, download, delete operations

  MusicCard({required this.video, required this.controller});

  @override
  Widget build(BuildContext context) {
    final duration = video.duration;
    final hours = duration?.inHours ?? 0;
    final minutes = duration?.inMinutes.remainder(60) ?? 0;
    final seconds = duration?.inSeconds.remainder(60) ?? 0;

    final formattedDuration =
        hours > 0
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
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  (video.isPlaying.value) ? Icons.stop : Icons.play_arrow,
                ),
                onPressed: () {
                  if (video.isPlaying.value) {
                    controller.stop(video);
                  } else {
                    controller.play(video);
                  }
                },
              ),
              const SizedBox(width: 8),
              (video.isDownloading.value)
                  ? const CircularProgressIndicator()
                  : (video.isDownloaded.value)
                  ? IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await controller.deleteFile(video);
                    },
                  )
                  : IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () async {
                      await controller.download(video);
                    },
                  ),
            ],
          );
        }),
      ),
    );
  }
}
