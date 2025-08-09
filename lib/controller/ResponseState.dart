import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:youtube_downloader/model/ResponseModel.dart';

class ResponseState {
  final ResponseModel model;

  RxBool isPlaying = false.obs;
  RxBool isDownloading = false.obs;
  RxBool isDownloaded = false.obs;

  ResponseState({required this.model});
}
