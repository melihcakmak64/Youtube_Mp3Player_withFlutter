import 'package:youtube_downloader/model/ResponseModel.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeExplodeService {
  final YoutubeExplode youtube = YoutubeExplode();
  VideoSearchList? searchResult;

  /// Ortak manifest alma ve en yüksek bitrate seçme
  Future<AudioOnlyStreamInfo> _getBestAudioStreamInfo(
    String url, {
    bool requireWatchPage = true,
  }) async {
    final manifest = await youtube.videos.streamsClient.getManifest(
      url,
      requireWatchPage: requireWatchPage,
    );
    return manifest.audioOnly.withHighestBitrate();
  }

  /// Sadece stream URL'sini döndürür
  Future<String> getMusicStreamUrl(String url) async {
    final streamInfo = await _getBestAudioStreamInfo(
      url,
      requireWatchPage: false,
    );
    return streamInfo.url.toString();
  }

  /// Hem stream hem boyut bilgisini döndürür
  Future<({Stream<List<int>> stream, int totalBytes})> getMusicStreamWithInfo(
    String url,
  ) async {
    final streamInfo = await _getBestAudioStreamInfo(url);
    final stream = youtube.videos.streamsClient.get(streamInfo);
    return (stream: stream, totalBytes: streamInfo.size.totalBytes);
  }

  /// Sadece stream döndürür
  Future<Stream<List<int>>> getMusicStream(String url) async {
    final streamInfo = await _getBestAudioStreamInfo(url);
    return youtube.videos.streamsClient.get(streamInfo);
  }

  /// Video arama
  Future<List<ResponseModel>> searchVideos(String query) async {
    searchResult = await youtube.search(query);
    return searchResult
            ?.map(
              (e) => ResponseModel(
                id: e.id,
                title: e.title,
                description: e.description,
                thumbnails: e.thumbnails,
                duration: e.duration,
                url: e.url,
              ),
            )
            .toList() ??
        [];
  }

  Future<List<StreamInfo>> getAllQualityOptions(String url) async {
    final manifest = await youtube.videos.streamsClient.getManifest(url);

    final audioList = manifest.audioOnly
        .where((a) => a.container.name == 'mp4')
        .toList();

    print("deneme");
    print(manifest.audioOnly.sortByBitrate());

    final videoList = manifest.video
        .where((v) => v.container.name == 'mp4')
        .toList();

    return [...audioList, ...videoList];
  }
}
