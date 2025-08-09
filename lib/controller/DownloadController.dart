import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_downloader/controller/ResponseState.dart';
import 'package:youtube_downloader/services/YoutubeExplodeService.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_downloader/model/ResponseModel.dart';
import 'package:youtube_downloader/services/MusicPlayerService.dart';
import 'package:youtube_downloader/services/PermissionHandler.dart';

class DownloadController extends GetxController {
  final Rx<Duration> currentPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;
  final RxList<ResponseState> _videoList = <ResponseState>[].obs;
  VideoSearchList? searchResult;
  //  final YoutubeExplode youtube = YoutubeExplode();
  final MusicPlayerService player = MusicPlayerService();
  Rx<ResponseState?> currentVideo = Rx<ResponseState?>(null);

  YoutubeExplodeService youtubeExplodeService = YoutubeExplodeService();
  RxBool sliderShown = false.obs;

  DownloadController() {
    player.getPositionStream().listen((position) {
      currentPosition.value = position;
    });

    player.getDurationStream().listen((duration) {
      if (duration != null) {
        totalDuration.value = duration;
      }
    });
  }

  void play(ResponseState video) async {
    if (currentVideo.value != null &&
        currentVideo.value!.model.url != video.model.url) {
      _updateVideo(currentVideo.value!, isPlaying: false);
    }

    _updateVideo(video, isPlaying: true);
    sliderShown.value = true;
    currentVideo.value = video;

    final url = await youtubeExplodeService.getMusicStreamUrl(video.model.url);
    await player.playMusicFromUrl(url);
  }

  Future<void> download(ResponseState video) async {
    if (player.isPlaying()) {
      player.stop(video.model);
    }

    final status =
        (await Permission.audio.status.isGranted) ||
        (await Permission.storage.status.isGranted);

    if (status) {
      _updateVideo(video, isDownloading: true);

      final stream = await youtubeExplodeService.getMusicStream(
        video.model.url,
      );

      final directory = await getExternalStorageDirectory();
      final downloadPath =
          '${directory!.parent.parent.parent.parent.path}/Download/MusicFolder';
      await Directory(downloadPath).create(recursive: true);

      final file = File('$downloadPath/${video.model.title}.mp3');
      final fileStream = file.openWrite();
      await stream.pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();

      _updateVideo(video, isDownloading: false, isDownloaded: true);
      await _markVideoAsDownloaded(video.model.url);

      Get.snackbar("Sonuc", "İndirme başarılı");
    } else {
      await PermissionHandler.chekPermission();
    }
  }

  void stop(ResponseState video) async {
    await player.stop(video.model);
    _updateVideo(video, isPlaying: false);
    sliderShown.value = false;
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

  RxList<ResponseState> getList() => _videoList;

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

  Future<void> _markVideoAsDownloaded(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedVideos = prefs.getStringList('downloadedVideos') ?? [];
    if (!downloadedVideos.contains(id)) {
      downloadedVideos.add(id);
      await prefs.setStringList('downloadedVideos', downloadedVideos);
    }
  }

  Future<void> _removeDownloadedVideo(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedVideos = prefs.getStringList('downloadedVideos') ?? [];
    if (downloadedVideos.contains(id)) {
      downloadedVideos.remove(id);
      await prefs.setStringList('downloadedVideos', downloadedVideos);
    }
  }

  Future<void> deleteFile(ResponseState video) async {
    final directory = await getExternalStorageDirectory();
    final downloadPath =
        '${directory!.parent.parent.parent.parent.path}/Download/MusicFolder/${video.model.title}.mp3';
    final file = File(downloadPath);

    if (await file.exists()) {
      await file.delete();
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
}
