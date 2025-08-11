import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/controller/DownloadController.dart';
import 'package:youtube_downloader/controller/MusicPlayerController.dart';
import 'package:youtube_downloader/controller/VideoListController.dart';
import 'package:youtube_downloader/helper/helper.dart';
import 'package:youtube_downloader/model/ResponseModel.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class MusicCard extends ConsumerWidget {
  final ResponseModel video;

  const MusicCard({super.key, required this.video});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadNotifier = ref.read(downloadControllerProvider.notifier);
    final musicPlayerNotifier = ref.read(musicPlayerProvider.notifier);
    final duration = video.duration;
    final formattedDuration = formatDuration(duration ?? Duration.zero);
    final isPlaying = ref.watch(isVideoPlayingProvider(video.url));

    return Card(
      child: ListTile(
        leading: FadeInImage.assetNetwork(
          placeholder: 'assets/placeholder-image.png',
          image: video.thumbnails.mediumResUrl,
          fit: BoxFit.cover,
        ),
        title: Text(
          "${video.title}",
          maxLines: 2,
          style: TextStyle(fontSize: 14),
        ),
        subtitle: Text(formattedDuration),
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
                  musicPlayerNotifier.play(video);
                }
              },
            ),
            const SizedBox(width: 8),

            // Progress / Download / Delete kısmı (izole edilmiş)
            Consumer(
              builder: (context, ref, _) {
                final downloadInfo = ref.watch(downloadInfoProvider(video.url));

                if (downloadInfo?.status == DownloadStatus.downloading) {
                  final percent = ((downloadInfo?.progress ?? 0) * 100)
                      .toStringAsFixed(0);
                  return Container(
                    alignment: Alignment.center,
                    height: 48,
                    width: 48,
                    child: Text(
                      "$percent%",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                } else if (downloadInfo?.status == DownloadStatus.downloaded) {
                  return IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await downloadNotifier.deleteDownload(video);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dosya silindi')),
                      );
                    },
                  );
                } else {
                  return IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () async {
                      // Kalite seçeneklerini çek
                      final options = await ref
                          .read(downloadControllerProvider.notifier)
                          .youtubeService
                          .getAllQualityOptions(video.url);
                      final audioOptions = options
                          .where((e) => e is AudioOnlyStreamInfo)
                          .toList();
                      final videoOptions = options
                          .where(
                            (e) =>
                                e is VideoOnlyStreamInfo ||
                                e is MuxedStreamInfo,
                          )
                          .toList();

                      if (options.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kalite seçenekleri bulunamadı'),
                          ),
                        );
                        return;
                      }

                      // Dialog göster
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: const Text('İndirme Kalitesi Seç'),
                            content: SizedBox(
                              width: double.minPositive,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (audioOptions.isNotEmpty) ...[
                                      const Text(
                                        'Ses Kalitesi',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: audioOptions.length,
                                        itemBuilder: (context, index) {
                                          final opt =
                                              audioOptions[index]
                                                  as AudioOnlyStreamInfo;
                                          return ListTile(
                                            title: Text(
                                              '${opt.bitrate.kiloBitsPerSecond} kbps • ${opt.container.name.toUpperCase()}',
                                            ),
                                            subtitle: Text(
                                              '${opt.size.totalMegaBytes.toStringAsFixed(2)} MB',
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${opt.bitrate.kiloBitsPerSecond} kbps ses indiriliyor...',
                                                  ),
                                                ),
                                              );
                                              ref
                                                  .read(
                                                    downloadControllerProvider
                                                        .notifier,
                                                  )
                                                  .startDownload(
                                                    video: video,
                                                    streamInfo: opt,
                                                  );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                    if (videoOptions.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Video Kalitesi',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: videoOptions.length,
                                        itemBuilder: (context, index) {
                                          final opt = videoOptions[index];
                                          String title = "";
                                          if (opt is VideoOnlyStreamInfo) {
                                            title =
                                                '${opt.qualityLabel} (${opt.size.totalMegaBytes.toStringAsFixed(2)} MB)';
                                          } else if (opt is MuxedStreamInfo) {
                                            title =
                                                '${opt.videoQualityLabel} (${opt.size.totalMegaBytes.toStringAsFixed(2)} MB)';
                                          }
                                          return ListTile(
                                            title: Text(title),
                                            subtitle: Text(opt.container.name),
                                            onTap: () {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '$title indiriliyor...',
                                                  ),
                                                ),
                                              );
                                              ref
                                                  .read(
                                                    downloadControllerProvider
                                                        .notifier,
                                                  )
                                                  .startDownload(
                                                    video: video,
                                                    streamInfo: opt,
                                                  );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
