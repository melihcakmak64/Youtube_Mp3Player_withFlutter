import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_downloader/controller/ResponseState.dart';
import 'package:youtube_downloader/services/DownloadService.dart';
import 'package:youtube_downloader/services/PermissionHandler.dart';
import 'package:youtube_downloader/services/SharedPreferencesService.dart';
import 'package:youtube_downloader/services/YoutubeExplodeService.dart';
import 'package:youtube_downloader/services/MusicPlayerService.dart';

class DownloadState {
  final List<ResponseState> videoList;
  final ResponseState? currentVideo;
  final Duration currentPosition;
  final Duration totalDuration;

  DownloadState({
    this.videoList = const [],
    this.currentVideo,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
  });

  DownloadState copyWith({
    List<ResponseState>? videoList,
    ResponseState? currentVideo,
    Duration? currentPosition,
    Duration? totalDuration,
  }) {
    return DownloadState(
      videoList: videoList ?? this.videoList,
      currentVideo: currentVideo ?? this.currentVideo,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }
}

class DownloadNotifier extends StateNotifier<DownloadState> {
  final MusicPlayerService player;
  final DownloadService downloadService;
  final YoutubeExplodeService youtubeExplodeService;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  DownloadNotifier({
    required this.player,
    required this.downloadService,
    required this.youtubeExplodeService,
  }) : super(DownloadState()) {
    _bindPlayerListeners();
  }

  void _bindPlayerListeners() {
    _positionSub = player.getPositionStream().listen((pos) {
      state = state.copyWith(currentPosition: pos);
    });

    _durationSub = player.getDurationStream().listen((dur) {
      if (dur != null) {
        state = state.copyWith(totalDuration: dur);
      }
    });
  }

  Future<void> play(ResponseState video) async {
    await _stopIfPlaying();
    _updateAndSetCurrent(video, isPlaying: true);

    final url = await youtubeExplodeService.getMusicStreamUrl(video.model.url);
    await player.playMusicFromUrl(url);
  }

  Future<void> stop(ResponseState video) async {
    await player.stop();
    _updateVideo(video, isPlaying: false);
  }

  Future<void> download(ResponseState video) async {
    if (!await _hasStoragePermission()) {
      await PermissionHandler.chekPermission();
      return;
    }

    _updateVideo(video, isDownloading: true);
    final stream = await youtubeExplodeService.getMusicStream(video.model.url);
    final savedFile = await downloadService.saveMusicStream(
      stream: stream,
      fileName: video.model.title,
    );

    await _markVideoAsDownloaded(video.model.url);
    _updateAndSetCurrent(video, isDownloading: false, isDownloaded: true);

    // Snackbar işlemini UI'da yapman gerekiyor,
    // buraya callback veya başka mekanizma ekleyebilirsin.
  }

  Future<void> _stopIfPlaying() async {
    if (player.isPlaying()) {
      await player.stop();
    }
  }

  Future<bool> _hasStoragePermission() async {
    return (await Permission.audio.status.isGranted) ||
        (await Permission.storage.status.isGranted);
  }

  Future<bool> isDownloaded(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedVideos = prefs.getStringList('downloadedVideos') ?? [];
    return downloadedVideos.contains(url);
  }

  Future<void> searchVideos(String query) async {
    final result = await youtubeExplodeService.searchVideos(query);

    // Yeni listeyi oluşturup, eski listeye ekliyoruz
    List<ResponseState> newList = [];
    for (var e in result) {
      final state = ResponseState(model: e);
      state.isDownloaded.value = await isDownloaded(e.url);
      newList.add(state);
    }

    state = state.copyWith(videoList: [...state.videoList, ...newList]);
  }

  void _updateAndSetCurrent(
    ResponseState video, {
    bool? isPlaying,
    bool? isDownloaded,
    bool? isDownloading,
  }) {
    _updateVideo(
      video,
      isPlaying: isPlaying,
      isDownloaded: isDownloaded,
      isDownloading: isDownloading,
    );
    state = state.copyWith(currentVideo: video);
  }

  Future<void> _markVideoAsDownloaded(String id) async {
    await SharedPreferencesService.addFile('downloadedVideos', id);
  }

  Future<void> _removeDownloadedVideo(String id) async {
    await SharedPreferencesService.removeFile('downloadedVideos', id);
  }

  Future<void> deleteFile(ResponseState video) async {
    final result = await downloadService.deleteFile(video.model.title);

    if (result) {
      await _removeDownloadedVideo(video.model.url);
      _updateVideo(video, isDownloaded: false);
      // UI'da snackbar gösterilmeli
    } else {
      // UI'da snackbar gösterilmeli
    }
  }

  void _updateVideo(
    ResponseState video, {
    bool? isDownloaded,
    bool? isPlaying,
    bool? isDownloading,
  }) {
    final idx = state.videoList.indexWhere((v) => v.model.id == video.model.id);
    if (idx == -1) return;

    // Riverpod’da ResponseState içindeki Rx<bool> durumları var,
    // istersen onları da state içinde tutup immutable yaparsın ama burada
    // orijinalden değiştirmeden direkt state güncellemesi yapacağız.

    // Ancak ResponseState içinde Rx<bool> kullanılmış. Riverpod'da bunu
    // direkt değiştirmek yerine immutable yapıp, state içinden yeni liste
    // oluşturarak değiştirmek daha doğru.

    // Burada örnek olarak ResponseState'i değiştirmeden döndürdük,
    // kendi modelinde güncelleme yapman gerekiyor.

    final updated = ResponseState(model: video.model);
    updated.isDownloaded.value = isDownloaded ?? video.isDownloaded.value;
    updated.isDownloading.value = isDownloading ?? video.isDownloading.value;

    final updatedList = [...state.videoList];
    updatedList[idx] = updated;

    state = state.copyWith(videoList: updatedList);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }

  void getNextPage() {}
}

// Provider tanımı
final downloadProvider = StateNotifierProvider<DownloadNotifier, DownloadState>(
  (ref) {
    final player = MusicPlayerService();
    final downloadService = DownloadService();
    final youtubeService = YoutubeExplodeService();

    return DownloadNotifier(
      player: player,
      downloadService: downloadService,
      youtubeExplodeService: youtubeService,
    );
  },
);
