import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/model/MusicPlayerState.dart';
import 'package:youtube_downloader/controller/controller_initializers.dart';
import 'package:youtube_downloader/model/ResponseModel.dart';
import 'package:youtube_downloader/services/MusicPlayerService.dart';
import 'package:youtube_downloader/services/YoutubeExplodeService.dart';

class MusicPlayerNotifier extends StateNotifier<MusicPlayerState> {
  final MusicPlayerService player;
  final YoutubeExplodeService youtubeService;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  MusicPlayerNotifier({required this.player, required this.youtubeService})
    : super(const MusicPlayerState(model: null)) {
    _bindPlayerStreams();
  }

  void _bindPlayerStreams() {
    _positionSub = player.getPositionStream().listen((pos) {
      state = state.copyWith(currentPosition: pos);
    });

    _durationSub = player.getDurationStream().listen((dur) {
      if (dur != null) {
        state = state.copyWith(totalDuration: dur);
      }
    });
  }

  Future<void> play(ResponseModel video) async {
    await stop();

    state = state.copyWith(
      model: video,
      isPlaying: true,
      currentPosition: Duration.zero,
    );

    try {
      final stream = await youtubeService.getAudioStream(video.url);
      await player.playMusicFromUrl(stream.url.toString());
    } catch (e) {
      state = state.copyWith(
        isPlaying: false,
        model: null,
        currentPosition: Duration.zero,
        totalDuration: Duration.zero,
      );
      rethrow;
    }
  }

  Future<void> stop() async {
    if (player.isPlaying()) {
      await player.stop();
    }
    state = state.copyWith(
      isPlaying: false,
      currentPosition: Duration.zero,
      totalDuration: Duration.zero,
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }
}

final musicPlayerProvider =
    StateNotifierProvider<MusicPlayerNotifier, MusicPlayerState>((ref) {
      final player = ref.read(musicPlayerServiceProvider);
      final youtubeService = ref.read(youtubeExplodeServiceProvider);
      return MusicPlayerNotifier(
        player: player,
        youtubeService: youtubeService,
      );
    });

// Seçici provider: sadece ilgili videonun oynatılıp oynatılmadığını verir
final isVideoPlayingProvider = Provider.family<bool, String>((ref, videoUrl) {
  final state = ref.watch(musicPlayerProvider);
  return state.model?.url == videoUrl && state.isPlaying;
});
