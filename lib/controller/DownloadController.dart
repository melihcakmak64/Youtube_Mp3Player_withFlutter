import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_downloader/core/StringExtensions.dart';
import 'package:youtube_downloader/model/ResponseModel.dart';
import 'package:youtube_downloader/services/DownloadService.dart';
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

  /// Kayıtlı dosyaları yükler, yoksa listeden siler
  Future<void> loadSavedDownloads() async {
    final saved = await SharedPreferencesService.getFiles('downloadedVideos');
    final restoredState = <String, DownloadInfo>{};

    for (var item in saved) {
      final filePath = item['path'];
      final extension = item['extension'] ?? '';
      final url = item['url'];

      if (filePath != null && File(filePath).existsSync()) {
        restoredState[url] = DownloadInfo(
          status: DownloadStatus.downloaded,
          progress: 1,
          extension: extension,
          path: filePath,
        );
      } else {
        await SharedPreferencesService.removeFile('downloadedVideos', url);
      }
    }

    state = restoredState;
  }

  /// İndirme başlat
  Future<void> startDownload({
    required ResponseModel video,
    required StreamInfo streamInfo,
  }) async {
    final videoUrl = video.url;
    try {
      if (!await _hasStoragePermission()) {
        await PermissionHandler.ensurePermissions();

        return;
      }

      updateState(
        videoUrl,
        status: DownloadStatus.downloading,
        progress: 0,
        extension: streamInfo.container.name,
      );

      final stream = youtubeService.youtube.videos.streamsClient.get(
        streamInfo,
      );

      final file = await downloadService.saveStream(
        stream: stream,
        fileName: video.title.sanitize(),
        extension: streamInfo.container.name,
        totalBytes: streamInfo.size.totalBytes,
        onProgress: (progress) async {
          updateState(videoUrl, progress: progress);
        },
      );

      await SharedPreferencesService.addFile('downloadedVideos', {
        'url': video.url,
        'extension': streamInfo.container.name,
        'title': video.title.sanitize(),
        'path': file.path,
      });

      updateState(
        videoUrl,
        status: DownloadStatus.downloaded,
        progress: 1,
        path: file.path,
        extension: streamInfo.container.name,
      );
    } catch (e) {
      updateState(videoUrl, status: DownloadStatus.failed);
    }
  }

  /// Depolama izni kontrolü
  Future<bool> _hasStoragePermission() async {
    return (await Permission.audio.status.isGranted) ||
        (await Permission.storage.status.isGranted);
  }

  /// İndirilen dosyayı sil
  Future<void> deleteDownload(ResponseModel video) async {
    final info = state[video.url];
    if (info == null) return;

    if (info.path != null && await downloadService.fileExists(info.path!)) {
      final result = await downloadService.deleteFile(info.path!);
      if (result) {
        await SharedPreferencesService.removeFile(
          'downloadedVideos',
          video.url,
        );
        updateState(
          video.url,
          status: DownloadStatus.notDownloaded,
          progress: 0,
          path: '',
        );
      }
    } else {
      await SharedPreferencesService.removeFile('downloadedVideos', video.url);
      updateState(
        video.url,
        status: DownloadStatus.notDownloaded,
        progress: 0,
        path: '',
      );
    }
  }

  void updateState(
    String videoUrl, {
    DownloadStatus? status,
    double? progress,
    String? extension,
    String? path,
  }) {
    final current = state[videoUrl] ?? DownloadInfo();
    state = {
      ...state,
      videoUrl: current.copyWith(
        status: status,
        progress: progress,
        extension: extension,
        path: path,
      ),
    };
  }
}

enum DownloadStatus { notDownloaded, downloading, downloaded, failed }

class DownloadInfo {
  final DownloadStatus status;
  final double progress;
  final String extension;
  final String? path;

  DownloadInfo({
    this.status = DownloadStatus.notDownloaded,
    this.progress = 0,
    this.extension = '',
    this.path,
  });

  DownloadInfo copyWith({
    DownloadStatus? status,
    double? progress,
    String? extension,
    String? path,
  }) {
    return DownloadInfo(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      extension: extension ?? this.extension,
      path: path ?? this.path,
    );
  }
}
