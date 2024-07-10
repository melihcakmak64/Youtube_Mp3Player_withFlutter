import 'dart:async';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:get/get.dart';

class DownloadController extends GetxController {
  final RxList<Video> _videoList = <Video>[].obs;

  VideoSearchList? searchResult;
  final YoutubeExplode youtube = YoutubeExplode();
  final AudioPlayer audioPlayer = AudioPlayer();

  RxString currentUrl = "".obs;

  void play(String link) async {
    currentUrl.value = link;
    StreamManifest manifest =
        await youtube.videos.streamsClient.getManifest(link);

    var streamInfo = manifest.audioOnly.withHighestBitrate();
    print(streamInfo.url.toString());
    await audioPlayer.setUrl(streamInfo.url.toString());

    audioPlayer.play();
  }

  void stop() async {
    await audioPlayer.stop();
    currentUrl.value = "";
  }

  Future<RxList<Video>> searchVideos(String query) async {
    searchResult = await youtube.search(query);
    searchResult!.forEach((p0) {
      _videoList.add(p0);
    });

    return _videoList;
  }

  RxList<Video> getList() {
    return _videoList;
  }

  Future<void> getNextPage() async {
    searchResult = await searchResult!.nextPage();
    searchResult!.forEach((p0) {
      _videoList.add(p0);
    });
  }
}
