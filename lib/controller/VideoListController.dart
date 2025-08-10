import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/controller/DownloadController.dart';
import 'package:youtube_downloader/controller/controller_initializers.dart';
import 'package:youtube_downloader/model/ResponseModel.dart';
import 'package:youtube_downloader/services/YoutubeExplodeService.dart';

class VideoListController extends StateNotifier<VideoListState> {
  final YoutubeExplodeService youtubeService;

  VideoListController(this.youtubeService) : super(VideoListState());

  Future<void> searchVideos(String query) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final results = await youtubeService.searchVideos(query);
      state = state.copyWith(videos: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class VideoListState {
  final List<ResponseModel> videos;
  final bool isLoading;
  final String? error;

  VideoListState({this.videos = const [], this.isLoading = false, this.error});

  VideoListState copyWith({
    List<ResponseModel>? videos,
    bool? isLoading,
    String? error,
  }) {
    return VideoListState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final videoListControllerProvider =
    StateNotifierProvider<VideoListController, VideoListState>((ref) {
      final youtubeService = ref.watch(youtubeExplodeServiceProvider);
      return VideoListController(youtubeService);
    });

final downloadControllerProvider =
    StateNotifierProvider<DownloadController, Map<String, DownloadInfo>>((ref) {
      final downloadService = ref.read(downloadServiceProvider);
      final youtubeService = ref.read(youtubeExplodeServiceProvider);

      final controller = DownloadController(
        downloadService: downloadService,
        youtubeService: youtubeService,
      );
      controller.loadSavedDownloads();
      return controller;
    });

final downloadInfoProvider = Provider.family<DownloadInfo?, String>((
  ref,
  videoId,
) {
  final state = ref.watch(downloadControllerProvider);
  return state[videoId];
});
