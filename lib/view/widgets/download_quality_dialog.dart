import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/controller/controller_initializers.dart';
import 'package:youtube_downloader/controller/video_list_controller.dart';
import 'package:youtube_downloader/helper/helper.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_downloader/model/ResponseModel.dart';

class DownloadQualityDialog extends ConsumerWidget {
  final ResponseModel video;

  const DownloadQualityDialog({super.key, required this.video});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadNotifier = ref.read(downloadControllerProvider.notifier);
    final optionsAsync = ref.watch(qualityOptionsProvider(video.url));

    return AlertDialog(
      title: const Text('Choose Download Quality'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: optionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text("Error: $err")),
          data: (options) {
            final audioOptions = options
                .whereType<AudioOnlyStreamInfo>()
                .toList();
            final videoOptions = options
                .whereType<VideoOnlyStreamInfo>()
                .toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (audioOptions.isNotEmpty) ...[
                    const Text(
                      'Sound Quality',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: audioOptions.length,
                      itemBuilder: (context, index) {
                        final opt = audioOptions[index];
                        return ListTile(
                          title: Text(
                            'Standart ${opt.container.name.toUpperCase()} (${opt.bitrate.kiloBitsPerSecond.round()}k)',
                          ),
                          subtitle: Text(
                            '${opt.size.totalMegaBytes.toStringAsFixed(2)} MB',
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${opt.bitrate.kiloBitsPerSecond} kbps ses indiriliyor...',
                                ),
                              ),
                            );
                            await downloadNotifier.startDownload(
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
                      'Video Quality',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: videoOptions.length,
                      itemBuilder: (context, index) {
                        final opt = videoOptions[index];
                        final title = getVideoQualityLabel(opt);
                        return ListTile(
                          title: Text(title),
                          subtitle: Text(
                            '${opt.size.totalMegaBytes.toStringAsFixed(2)} MB',
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$title indiriliyor...')),
                            );
                            await downloadNotifier.startDownload(
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
            );
          },
        ),
      ),
    );
  }
}
