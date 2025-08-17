import 'package:youtube_downloader/model/ResponseModel.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeExplodeService {
  final YoutubeExplode youtube = YoutubeExplode();

  /// Video arama
  Future<List<ResponseModel>> searchVideos(String query) async {
    final searchResult = await youtube.search(query);
    return searchResult
        .map(
          (e) => ResponseModel(
            id: e.id,
            title: e.title,
            description: e.description,
            thumbnails: e.thumbnails,
            duration: e.duration,
            url: e.url,
          ),
        )
        .toList();
  }

  Future<AudioOnlyStreamInfo> getAudioStream(
    String url, {
    bool requireWatchPage = false,
    bool isLowest = true,
  }) async {
    final manifest = await youtube.videos.streamsClient.getManifest(
      url,
      requireWatchPage: requireWatchPage,
    );
    return isLowest
        ? manifest.audioOnly.sortByBitrate().first
        : manifest.audioOnly.withHighestBitrate();
  }

  Future<List<StreamInfo>> getAllQualityOptions(String url) async {
    final manifest = await youtube.videos.streamsClient.getManifest(url);

    // Ses listesi (MP4 formatı)
    final audioList = manifest.audioOnly
        .where((a) => a.container.name == 'mp4')
        .toList();

    // Video listesi (MP4 formatı)
    final rawVideoList = manifest.video
        .where((v) => v.container.name == 'mp4')
        .toList();

    print(rawVideoList);

    // Aynı çözünürlükteki streamlerden sadece en yüksek bitrate'i al
    Map<int, VideoOnlyStreamInfo> videoMap = {}; // key = height
    for (var v in rawVideoList) {
      if (v is VideoOnlyStreamInfo) {
        final current = videoMap[v.videoResolution.height];
        if (current == null ||
            v.bitrate.kiloBitsPerSecond > current.bitrate.kiloBitsPerSecond) {
          videoMap[v.videoResolution.height] = v;
        }
      }
    }

    // Filtrelenmiş video listesi
    final videoList = [...videoMap.values];

    return [...audioList, ...videoList];
  }
}
