import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:get/get.dart';

class DownloadController extends GetxController {
  final RxList<Video> _videoList = <Video>[].obs;

  VideoSearchList? searchResult;
  final YoutubeExplode youtube = YoutubeExplode();
  final AudioPlayer audioPlayer = AudioPlayer();

  PlayerState state = PlayerState.stopped;

  RxString currentUrl = "".obs;

  void play(String link) async {
    state = PlayerState.playing;
    currentUrl.value = link;
    StreamManifest manifest =
        await youtube.videos.streamsClient.getManifest(link);
    var streamInfo = manifest.audioOnly.withHighestBitrate();

    Stream<List<int>> stream = youtube.videos.streamsClient.get(streamInfo);

    Uint8List bytes2 = await readBytes(stream);
    print("2.bytelar okundu..");

    audioPlayer.play(BytesSource(bytes2));
  }

  Future<Uint8List> readBytes(Stream<List<int>> byteStream) async {
    // Take the first 100 bytes
    List<int> first100Bytes = await byteStream.fold<List<int>>(
      <int>[],
      (buffer, chunk) => buffer..addAll(chunk),
    );

    // Convert the List<int> to Uint8List
    Uint8List uint8List = Uint8List.fromList(first100Bytes);

    return uint8List;
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
