import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_downloader/model/ResponseModel.dart';
import 'package:youtube_downloader/services/DownloadService.dart';
import 'package:youtube_downloader/services/NotificationService.dart';
import 'package:youtube_downloader/services/PermissionHandler.dart';
import 'package:youtube_downloader/services/SharedPreferencesService.dart';
import 'package:youtube_downloader/services/YoutubeExplodeService.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded, failed }

class DownloadInfo {
  final DownloadStatus status;
  final double progress; // 0..1 arası
  final ResponseModel video;

  DownloadInfo({
    required this.video,
    this.status = DownloadStatus.notDownloaded,
    this.progress = 0,
  });

  DownloadInfo copyWith({DownloadStatus? status, double? progress}) {
    return DownloadInfo(
      video: video,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}

class DownloadController extends StateNotifier<Map<String, DownloadInfo>> {
  final DownloadService downloadService;
  final YoutubeExplodeService youtubeService;

  DownloadController({
    required this.downloadService,
    required this.youtubeService,
  }) : super({});

  DownloadInfo? getDownloadInfo(String videoId) {
    return state[videoId];
  }

  Future<void> startDownload(ResponseModel video) async {
    final videoId = video.url;

    if (state[videoId]?.status == DownloadStatus.downloading) return;

    // İndiriliyor durumuna setle
    state = {
      ...state,
      videoId: DownloadInfo(
        video: video,
        status: DownloadStatus.downloading,
        progress: 0,
      ),
    };

    try {
      if (!await _hasStoragePermission()) {
        await PermissionHandler.chekPermission();
        // İzin verilmezse iptal et
        state = {
          ...state,
          videoId: DownloadInfo(
            video: video,
            status: DownloadStatus.notDownloaded,
            progress: 0,
          ),
        };
        return;
      }

      // youtubeService'ten stream + totalBytes al
      final musicData = await youtubeService.getMusicStreamWithInfo(video.url);

      await downloadService.saveMusicStream(
        stream: musicData.stream,
        fileName: video.title,
        totalBytes: musicData.totalBytes,
        onProgress: (progress) async {
          final current = state[videoId];
          if (current != null) {
            state = {...state, videoId: current.copyWith(progress: progress)};
          }
          int percent = (progress * 100).toInt();
          await NotificationService.showDownloadProgress(
            id: videoId.hashCode,
            title: video.title,
            progress: percent,
          );
        },
      );

      await SharedPreferencesService.addFile('downloadedVideos', video.url);

      // İndirme tamamlandı olarak setle
      state = {
        ...state,
        videoId: DownloadInfo(
          video: video,
          status: DownloadStatus.downloaded,
          progress: 1,
        ),
      };
      await NotificationService.showDownloadProgress(
        id: videoId.hashCode,
        title: video.title,
        progress: 100,
      );
    } catch (e) {
      await NotificationService.cancel(videoId.hashCode);

      // Hata durumunda
      state = {
        ...state,
        videoId: DownloadInfo(
          video: video,
          status: DownloadStatus.failed,
          progress: 0,
        ),
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

    final result = await downloadService.deleteFile(info.video.title);

    if (result) {
      await SharedPreferencesService.removeFile(
        'downloadedVideos',
        info.video.url,
      );
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
