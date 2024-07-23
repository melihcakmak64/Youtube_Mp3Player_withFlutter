import 'dart:async';
import 'dart:io';
import 'package:music_player/model/newModel.dart';
import 'package:music_player/services/MusicPlayerService.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:get/get.dart';

class DownloadController extends GetxController {
  final RxList<ExtendedVideo> _videoList = <ExtendedVideo>[].obs;

  VideoSearchList? searchResult;
  final YoutubeExplode youtube = YoutubeExplode();
  final MusicPlayerService player = MusicPlayerService();

  RxString currentUrl = "".obs;
  RxBool isDownloading = false.obs;

  Future<String> getMusicUrl(String link) async {
    currentUrl.value = link;

    StreamManifest manifest =
        await youtube.videos.streamsClient.getManifest(link);
    var streamInfo = manifest.audioOnly.withHighestBitrate();
    return streamInfo.url.toString();
  }

  void play(String link) async {
    String url = await getMusicUrl(link);
    await player.playMusicFromUrl(url);
  }

  Future<void> download(ExtendedVideo video) async {
    var status = await Permission.storage.status;
    if (status.isGranted) {
      currentUrl.value = video.url;
      isDownloading.value = true;
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
        currentUrl.value = "";
        isDownloading.value = false;
        await _markVideoAsDownloaded(video.url);
        Get.snackbar("Sonuc", "İndirme başarılı");
        // Update the video in the list
        _updateVideoAsDownloaded(video);
      }
    } else {
      status = await Permission.storage.request();
    }
  }

  void stop() async {
    await player.stop();
    currentUrl.value = "";
  }

  Future<bool> isDownloaded(String url) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> downloadedVideos =
        prefs.getStringList('downloadedVideos') ?? [];
    return downloadedVideos.contains(url);
  }

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

  RxList<ExtendedVideo> getList() {
    return _videoList;
  }

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

  Future<void> _markVideoAsDownloaded(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> downloadedVideos =
        prefs.getStringList('downloadedVideos') ?? [];

    if (!downloadedVideos.contains(id)) {
      downloadedVideos.add(id);
      await prefs.setStringList('downloadedVideos', downloadedVideos);
    }
  }

  Future<void> _removeDownloadedVideo(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> downloadedVideos =
        prefs.getStringList('downloadedVideos') ?? [];
    if (downloadedVideos.contains(id)) {
      downloadedVideos.remove(id);
      await prefs.setStringList('downloadedVideos', downloadedVideos);
    }
  }

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

  void _updateVideoAsDownloaded(ExtendedVideo video) {
    video.isDownloaded.value = true;
  }

  void _updateVideoAsNotDownloaded(ExtendedVideo video) {
    video.isDownloaded.value = false;
  }
}
