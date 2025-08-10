import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/controller/DownloadController.dart';
import 'package:youtube_downloader/controller/MusicPlayerController.dart';
import 'package:youtube_downloader/controller/ResponseState.dart';
import 'package:youtube_downloader/helper/helper.dart';

class MusicCard extends ConsumerWidget {
  final ResponseState video;

  const MusicCard({super.key, required this.video});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadNotifier = ref.read(downloadProvider.notifier);
    final musicPlayerNotifier = ref.read(musicPlayerProvider.notifier);
    final duration = video.model.duration;
    final formattedDuration = formatDuration(duration ?? Duration.zero);
    final isPlaying = ref.watch(isVideoPlayingProvider(video.model.url));

    return Card(
      child: ListTile(
        leading: FadeInImage.assetNetwork(
          placeholder: 'assets/placeholder-image.png',
          image: video.model.thumbnails.mediumResUrl,
          fit: BoxFit.cover,
        ),
        title: Text("${video.model.title} ($formattedDuration)"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play/Stop Button
            IconButton(
              icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
              onPressed: () {
                if (isPlaying) {
                  musicPlayerNotifier.stop();
                } else {
                  musicPlayerNotifier.play(video.model);
                }
              },
            ),

            const SizedBox(width: 8),

            // Download/Delete Button
            Builder(
              builder: (context) {
                if (video.isDownloading.value) {
                  return const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                } else if (video.isDownloaded.value) {
                  return IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await downloadNotifier.deleteFile(video);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dosya silindi')),
                      );
                    },
                  );
                } else {
                  return IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () async {
                      await downloadNotifier.download(video);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('İndirme başarılı')),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
