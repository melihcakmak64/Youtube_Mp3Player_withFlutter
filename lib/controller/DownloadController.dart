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

  DownloadInfo({this.status = DownloadStatus.notDownloaded, this.progress = 0});

  DownloadInfo copyWith({DownloadStatus? status, double? progress}) {
    return DownloadInfo(
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
    final videoUrl = video.url;

    if (state[videoUrl]?.status == DownloadStatus.downloading) return;

    // İndiriliyor durumuna setle
    state = {
      ...state,
      videoUrl: DownloadInfo(status: DownloadStatus.downloading, progress: 0),
    };

    try {
      if (!await _hasStoragePermission()) {
        await PermissionHandler.chekPermission();
        // İzin verilmezse iptal et
        state = {
          ...state,
          videoUrl: DownloadInfo(
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

      // İndirme tamamlandı olarak setle
      state = {
        ...state,
        videoUrl: DownloadInfo(status: DownloadStatus.downloaded, progress: 1),
      };
      await NotificationService.showDownloadProgress(
        id: videoUrl.hashCode,
        title: video.title,
        progress: 100,
      );
    } catch (e) {
      await NotificationService.cancel(videoUrl.hashCode);

      // Hata durumunda
      state = {
        ...state,
        videoUrl: DownloadInfo(status: DownloadStatus.failed, progress: 0),
      };
    }
  }

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

  Future<bool> _hasStoragePermission() async {
    return (await Permission.audio.status.isGranted) ||
        (await Permission.storage.status.isGranted);
  }

  Future<void> deleteDownload(ResponseModel video) async {
    final info = state[video.url];
    if (info == null) return;

    final result = await downloadService.deleteFile(video.title);

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
