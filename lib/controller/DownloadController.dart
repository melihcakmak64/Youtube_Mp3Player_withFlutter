import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_downloader/controller/ResponseState.dart';
import 'package:youtube_downloader/services/DownloadService.dart';
import 'package:youtube_downloader/services/SharedPreferencesService.dart';
import 'package:youtube_downloader/services/YoutubeExplodeService.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_downloader/services/MusicPlayerService.dart';
import 'package:youtube_downloader/services/PermissionHandler.dart';

class DownloadController extends GetxController {
  final Rx<Duration> currentPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;
  final RxList<ResponseState> _videoList = <ResponseState>[].obs;
  VideoSearchList? searchResult;
  Rx<ResponseState?> currentVideo = Rx<ResponseState?>(null);

  RxList<ResponseState> getList() => _videoList;

  final player = MusicPlayerService();
  final downloadService = DownloadService();
  final youtubeExplodeService = YoutubeExplodeService();

  @override
  void onInit() {
    super.onInit();
    _bindPlayerListeners();
  }

  void _bindPlayerListeners() {
    player.getPositionStream().listen((pos) => currentPosition.value = pos);
    player.getDurationStream().listen((dur) {
      if (dur != null) totalDuration.value = dur;
    });
  }

  Future<void> play(ResponseState video) async {
    _stopIfPlaying();
    _updateAndSetCurrent(video, isPlaying: true);

    final url = await youtubeExplodeService.getMusicStreamUrl(video.model.url);
    await player.playMusicFromUrl(url);
  }

  void stop(ResponseState video) async {
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

    // UI'da snackbar tetikle
    Get.snackbar(
      "İndirme başarılı",
      "Çalmak için tıklayın.",
      onTap: (_) {
        _stopIfPlaying();
        player.playMusicFromFile(savedFile.path);
        _updateAndSetCurrent(
          video,
          isDownloading: false,
          isDownloaded: true,
          isPlaying: true,
        );
      },
    );
  }

  void _stopIfPlaying() {
    if (player.isPlaying()) player.stop();
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
    for (var e in result) {
      final state = ResponseState(model: e);
      state.isDownloaded.value = await isDownloaded(e.url);
      _videoList.add(state);
    }
  }

  void _updateAndSetCurrent(
    ResponseState video, {
    bool? isPlaying,
    bool? isDownloaded,
    bool? isDownloading,
  }) {
    _updateVideo(
      video,
      isDownloaded: isDownloaded,
      isPlaying: isPlaying,
      isDownloading: isDownloading,
    );
    currentVideo.value = video;
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
      Get.snackbar("Sonuc", "Silme başarılı");
    } else {
      Get.snackbar("Sonuc", "Dosya bulunamadı");
    }
  }

  void _updateVideo(
    ResponseState video, {
    bool? isDownloaded,
    bool? isPlaying,
    bool? isDownloading,
  }) {
    final videoState = _videoList.firstWhereOrNull(
      (v) => v.model.id == video.model.id,
    );
    if (videoState != null) {
      videoState.isDownloaded.value =
          isDownloaded ?? videoState.isDownloaded.value;
      videoState.isPlaying.value = isPlaying ?? videoState.isPlaying.value;
      videoState.isDownloading.value =
          isDownloading ?? videoState.isDownloading.value;
    }
  }

  Future<void> getNextPage() async {
    // searchResult = await searchResult!.nextPage();
    // for (var p0 in searchResult!) {
    //   final video = ResponseModel(
    //     id: VideoId(p0.id.value),
    //     title: p0.title,
    //     publishDate: p0.publishDate,
    //     description: p0.description,
    //     duration: p0.duration,
    //     thumbnails: p0.thumbnails,
    //     url: p0.url,
    //   );
    //   _videoList.add(video);
    // }
  }
}
