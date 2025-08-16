import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/controller/VideoListController.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_downloader/model/ResponseModel.dart';

class DownloadQualityDialog extends ConsumerStatefulWidget {
  final ResponseModel video;

  const DownloadQualityDialog({super.key, required this.video});

  @override
  ConsumerState<DownloadQualityDialog> createState() =>
      _DownloadQualityDialogState();
}

class _DownloadQualityDialogState extends ConsumerState<DownloadQualityDialog> {
  bool isLoading = true;
  Object? error;
  List<StreamInfo> options = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final downloadNotifier = ref.read(downloadControllerProvider.notifier);
      final result = await downloadNotifier.youtubeService.getAllQualityOptions(
        widget.video.url,
      );

      if (mounted) {
        setState(() {
          options = result;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(child: Text("Hata: $error"))
            : SingleChildScrollView(
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
                                video: widget.video,
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
                            onTap: () async {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$title indiriliyor...'),
                                ),
                              );
                              await downloadNotifier.startDownload(
                                video: widget.video,
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
