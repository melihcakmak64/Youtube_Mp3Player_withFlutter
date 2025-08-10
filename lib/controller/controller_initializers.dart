// 1. Singleton servis providerları:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/controller/DownloadController.dart';
import 'package:youtube_downloader/controller/MusicPlayerController.dart';
import 'package:youtube_downloader/model/MusicPlayerState.dart';
import 'package:youtube_downloader/controller/VideoListController.dart';
import 'package:youtube_downloader/services/DownloadService.dart';
import 'package:youtube_downloader/services/MusicPlayerService.dart';
import 'package:youtube_downloader/services/YoutubeExplodeService.dart';

final musicPlayerServiceProvider = Provider<MusicPlayerService>((ref) {
  return MusicPlayerService();
});

final youtubeExplodeServiceProvider = Provider<YoutubeExplodeService>((ref) {
  return YoutubeExplodeService();
});

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService();
});
