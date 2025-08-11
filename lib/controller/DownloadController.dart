import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_downloader/core/StringExtensions.dart';
import 'package:youtube_downloader/helper/helper.dart';
import 'package:youtube_downloader/model/ResponseModel.dart';
import 'package:youtube_downloader/services/DownloadService.dart';
import 'package:youtube_downloader/services/NotificationService.dart';
import 'package:youtube_downloader/core/PermissionHandler.dart';
import 'package:youtube_downloader/core/SharedPreferencesService.dart';
import 'package:youtube_downloader/services/YoutubeExplodeService.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadController extends StateNotifier<Map<String, DownloadInfo>> {
  final DownloadService downloadService;
  final YoutubeExplodeService youtubeService;

  DownloadController({
    required this.downloadService,
    required this.youtubeService,
  }) : super({});

  Future<void> loadSavedDownloads() async {
    final savedUrls = await SharedPreferencesService.getFiles(
      'downloadedVideos',
    );

    final restoredState = <String, DownloadInfo>{};

    for (var url in savedUrls) {
      // Burada video başlığını, thumbnail vs. yeniden bulmak için youtubeService kullanabilirsin
      restoredState[url] = DownloadInfo(
        status: DownloadStatus.downloaded,
        progress: 1,
      );
    }

    state = restoredState;
  }

  Future<void> startDownload({
    required ResponseModel video,
    required StreamInfo
    streamInfo, // AudioOnlyStreamInfo veya VideoStreamInfo olabilir
  }) async {
    final videoUrl = video.url;

    state = {
      ...state,
      videoUrl: DownloadInfo(
        status: DownloadStatus.downloading,
        progress: 0,
        extension: streamInfo.container.name,
      ),
    };

    try {
      if (!await _hasStoragePermission()) {
        await PermissionHandler.chekPermission();
        state = {
          ...state,
          videoUrl: DownloadInfo(
            status: DownloadStatus.notDownloaded,
            progress: 0,
          ),
        };
        return;
      }

      final stream = youtubeService.youtube.videos.streamsClient.get(
        streamInfo,
      );

      await downloadService.saveStream(
        stream: stream,
        fileName: video.title,
        extension: streamInfo.container.name, // mp3, mp4 vb.
        totalBytes: streamInfo.size.totalBytes,
        onProgress: (progress) async {
          final current = state[videoUrl];
          if (current != null) {
            state = {...state, videoUrl: current.copyWith(progress: progress)};
          }
          int percent = (progress * 100).toInt();
          await NotificationService.showDownloadProgress(
            id: videoUrl.hashCode,
            title: video.title,
            progress: percent,
          );
        },
      );

      await SharedPreferencesService.addFile('downloadedVideos', video.url);

      state = {
        ...state,
        videoUrl: DownloadInfo(
          status: DownloadStatus.downloaded,
          progress: 1,
          extension: streamInfo.container.name,
        ),
      };
      await NotificationService.showDownloadProgress(
        id: videoUrl.hashCode,
        title: video.title,
        progress: 100,
      );
    } catch (e) {
      await NotificationService.cancel(videoUrl.hashCode);
      state = {
        ...state,
        videoUrl: DownloadInfo(status: DownloadStatus.failed, progress: 0),
      };
    }
  }

  Future<bool> _hasStoragePermission() async {
    return (await Permission.audio.status.isGranted) ||
        (await Permission.storage.status.isGranted);
  }

  Future<void> deleteDownload(ResponseModel video) async {
    final info = state[video.url];
    if (info == null) return;

    final result = await downloadService.deleteFile(
      "${video.title}.${info.extension}",
    );

    if (result) {
      await SharedPreferencesService.removeFile('downloadedVideos', video.url);
      // Bildirimi iptal et
      await NotificationService.cancel(video.url.hashCode);
      state = {
        ...state,
        video.url: info.copyWith(
          status: DownloadStatus.notDownloaded,
          progress: 0,
        ),
      };
    }
  }
}

enum DownloadStatus { notDownloaded, downloading, downloaded, failed }

class DownloadInfo {
  final DownloadStatus status;
  final double progress; // 0..1 arası
  final String extension; // "mp3", "mp4", "webm" gibi

  DownloadInfo({
    this.status = DownloadStatus.notDownloaded,
    this.progress = 0,
    this.extension = '',
  });

  DownloadInfo copyWith({
    DownloadStatus? status,
    double? progress,
    String? extension,
  }) {
    return DownloadInfo(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      extension: extension ?? this.extension,
    );
  }
}
