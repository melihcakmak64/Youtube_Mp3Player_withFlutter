import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/controller/VideoListController.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_downloader/model/ResponseModel.dart';

class DownloadQualityDialog extends ConsumerWidget {
  final ResponseModel video;
  final List<StreamInfo> options;

  const DownloadQualityDialog({
    super.key,
    required this.video,
    required this.options,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadNotifier = ref.read(downloadControllerProvider.notifier);

    final audioOptions = options.whereType<AudioOnlyStreamInfo>().toList();
    final videoOptions = options
        .where((e) => e is VideoOnlyStreamInfo || e is MuxedStreamInfo)
        .toList();

    return AlertDialog(
      title: const Text('İndirme Kalitesi Seç'),
      content: SizedBox(
        width: double.minPositive,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (audioOptions.isNotEmpty) ...[
                const Text(
                  'Ses Kalitesi',
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
                        '${opt.bitrate.kiloBitsPerSecond} kbps • ${opt.container.name.toUpperCase()}',
                      ),
                      subtitle: Text(
                        '${opt.size.totalMegaBytes.toStringAsFixed(2)} MB',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${opt.bitrate.kiloBitsPerSecond} kbps ses indiriliyor...',
                            ),
                          ),
                        );
                        downloadNotifier.startDownload(
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
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$title indiriliyor...')),
                        );
                        downloadNotifier.startDownload(
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
  }
}
