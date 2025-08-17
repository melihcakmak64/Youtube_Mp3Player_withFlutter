import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/services/download_service.dart';
import 'package:youtube_downloader/services/music_player_service.dart';
import 'package:youtube_downloader/services/youtube_explode_service.dart';

final musicPlayerServiceProvider = Provider<MusicPlayerService>((ref) {
  return MusicPlayerService();
});

final youtubeExplodeServiceProvider = Provider<YoutubeExplodeService>((ref) {
  return YoutubeExplodeService();
});

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService();
});
