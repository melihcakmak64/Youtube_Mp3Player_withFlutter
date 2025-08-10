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

// 2. MusicPlayerNotifier sadece servisleri ref ile alıyor:
final musicPlayerProvider =
    StateNotifierProvider<MusicPlayerNotifier, MusicPlayerState>((ref) {
      final player = ref.read(musicPlayerServiceProvider);
      final youtubeService = ref.read(youtubeExplodeServiceProvider);
      return MusicPlayerNotifier(
        player: player,
        youtubeService: youtubeService,
      );
    });

final videoListControllerProvider =
    StateNotifierProvider<VideoListController, VideoListState>((ref) {
      final youtubeService = ref.watch(youtubeExplodeServiceProvider);
      return VideoListController(youtubeService);
    });

final downloadControllerProvider =
    StateNotifierProvider<DownloadController, Map<String, DownloadInfo>>((ref) {
      final downloadService = ref.read(downloadServiceProvider);
      final youtubeService = ref.read(youtubeExplodeServiceProvider);
      return DownloadController(
        downloadService: downloadService,
        youtubeService: youtubeService,
      );
    });

final downloadInfoProvider = Provider.family<DownloadInfo?, String>((
  ref,
  videoId,
) {
  final state = ref.watch(downloadControllerProvider);
  return state[videoId];
});
