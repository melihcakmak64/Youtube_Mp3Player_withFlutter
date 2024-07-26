import 'dart:async';
import 'dart:io';
import 'package:music_player/model/newModel.dart';
import 'package:music_player/services/MusicPlayerService.dart';
import 'package:music_player/services/PermissionHandler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:get/get.dart';

class DownloadController extends GetxController {
  final Rx<Duration> currentPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;
  final RxList<ExtendedVideo> _videoList = <ExtendedVideo>[].obs;
  VideoSearchList? searchResult;
  final YoutubeExplode youtube = YoutubeExplode();
  final MusicPlayerService player = MusicPlayerService();
  ExtendedVideo? currentVideo;

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

/////////////////////////////////////////////
  Future<String> getMusicUrl(ExtendedVideo video) async {
    StreamManifest manifest =
        await youtube.videos.streamsClient.getManifest(video.url);
    var streamInfo = manifest.audioOnly.withHighestBitrate();

    return streamInfo.url.toString();
  }

/////////////////////////////////////////////
  void play(ExtendedVideo video) async {
    if (currentVideo != null) {
      if (currentVideo!.url != video.url) {
        currentVideo!.isPlaying.value = false;
      }
    }
    video.isPlaying.value = true;

    String url = await getMusicUrl(video);
    await player.playMusicFromUrl(url);
    currentVideo = video;
  }
/////////////////////////////////////////////

  Future<void> download(ExtendedVideo video) async {
    if (player.isPlaying()) {
      player.stop(video);
    }
    var status = (await Permission.audio.status.isGranted) ||
        (await Permission.storage.status.isGranted);
    if (status) {
      video.isDownloading.value = true;
      StreamManifest manifest =
          await youtube.videos.streamsClient.getManifest(video.url);
      AudioOnlyStreamInfo streamInfo = manifest.audioOnly.withHighestBitrate();
      if (streamInfo != null) {
        var stream = youtube.videos.streamsClient.get(streamInfo);
        var directory = await getExternalStorageDirectory();
        String downloadPath =
            '${directory!.parent.parent.parent.parent.path}/Download/MusicFolder';
        await Directory(downloadPath).create(recursive: true);
        File file = File('$downloadPath/${video.title}.mp3');
        var fileStream = file.openWrite();
        await stream.pipe(fileStream);
        await fileStream.flush();
        await fileStream.close();
        video.isDownloading.value = false;
        await _markVideoAsDownloaded(video.url);
        Get.snackbar("Sonuc", "İndirme başarılı");
        // Update the video in the list
        _updateVideoAsDownloaded(video);
      }
    } else {
      await PermissionHandler.chekPermission();
    }
  }

/////////////////////////////////////////////

  void stop(ExtendedVideo video) async {
    await player.stop(video);
    video.isPlaying.value = false;
  }

/////////////////////////////////////////////
  Future<bool> isDownloaded(String url) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> downloadedVideos =
        prefs.getStringList('downloadedVideos') ?? [];
    return downloadedVideos.contains(url);
  }

/////////////////////////////////////////////
  Future<RxList<ExtendedVideo>> searchVideos(String query) async {
    searchResult = await youtube.search(query);
    searchResult!.forEach((p0) async {
      var video = ExtendedVideo(
          id: VideoId(p0.id.value),
          title: p0.title,
          author: p0.author,
          channelId: ChannelId(p0.channelId.value),
          uploadDate: p0.uploadDate,
          uploadDateRaw: p0.uploadDateRaw,
          publishDate: p0.publishDate,
          description: p0.description,
          duration: p0.duration,
          thumbnails: p0.thumbnails,
          keywords: p0.keywords ?? [],
          engagement: p0.engagement,
          isLive: p0.isLive,
          url: p0.url,
          isDownloaded:
              await isDownloaded(p0.url) // isDownloaded attribute'u ayarla
          );
      _videoList.add(video);
    });

    return _videoList;
  }

/////////////////////////////////////////////
  RxList<ExtendedVideo> getList() {
    return _videoList;
  }

/////////////////////////////////////////////
  Future<void> getNextPage() async {
    searchResult = await searchResult!.nextPage();
    searchResult!.forEach((p0) async {
      var video = ExtendedVideo(
          id: VideoId(p0.id.value),
          title: p0.title,
          author: p0.author,
          channelId: ChannelId(p0.channelId.value),
          uploadDate: p0.uploadDate,
          uploadDateRaw: p0.uploadDateRaw,
          publishDate: p0.publishDate,
          description: p0.description,
          duration: p0.duration,
          thumbnails: p0.thumbnails,
          keywords: p0.keywords ?? [],
          engagement: p0.engagement,
          isLive: p0.isLive,
          url: p0.url,
          isDownloaded:
              await isDownloaded(p0.url) // isDownloaded attribute'u ayarla
          );
      _videoList.add(video);
    });
  }

/////////////////////////////////////////////
  Future<void> _markVideoAsDownloaded(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> downloadedVideos =
        prefs.getStringList('downloadedVideos') ?? [];

    if (!downloadedVideos.contains(id)) {
      downloadedVideos.add(id);
      await prefs.setStringList('downloadedVideos', downloadedVideos);
    }
  }

/////////////////////////////////////////////
  Future<void> _removeDownloadedVideo(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> downloadedVideos =
        prefs.getStringList('downloadedVideos') ?? [];
    if (downloadedVideos.contains(id)) {
      downloadedVideos.remove(id);
      await prefs.setStringList('downloadedVideos', downloadedVideos);
    }
  }

/////////////////////////////////////////////
  Future<void> deleteFile(ExtendedVideo video) async {
    var directory = await getExternalStorageDirectory();
    String downloadPath =
        '${directory!.parent.parent.parent.parent.path}/Download/MusicFolder/${video.title}.mp3';
    File file = File(downloadPath);
    if (await file.exists()) {
      await file.delete();
      await _removeDownloadedVideo(video.url);

      Get.snackbar("Sonuc", "Silme başarılı");
      _updateVideoAsNotDownloaded(video);
    } else {
      Get.snackbar("Sonuc", "Dosya bulunamadı");
    }
  }

/////////////////////////////////////////////
  void _updateVideoAsDownloaded(ExtendedVideo video) {
    video.isDownloaded.value = true;
  }

/////////////////////////////////////////////
  void _updateVideoAsNotDownloaded(ExtendedVideo video) {
    video.isDownloaded.value = false;
  }

  /////////////////////////////////////////////
}
