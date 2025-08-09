import 'package:youtube_downloader/model/ResponseModel.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeExplodeService {
  final YoutubeExplode youtube = YoutubeExplode();
  VideoSearchList? searchResult;

  Future<String> getMusicStreamUrl(String url) async {
    final manifest = await youtube.videos.streamsClient.getManifest(url);
    final streamInfo = manifest.audioOnly.withHighestBitrate();
    return streamInfo.url.toString();
  }

  Future<Stream<List<int>>> getMusicStream(String url) async {
    final manifest = await youtube.videos.streamsClient.getManifest(url);
    final streamInfo = manifest.audioOnly.withHighestBitrate();
    final stream = youtube.videos.streamsClient.get(streamInfo);
    return stream;
  }

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
}
