import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import "package:youtube_explode_dart/src/reverse_engineering/pages/watch_page.dart";

class ExtendedVideo {
  final VideoId id;
  final String title;
  final String author;
  final ChannelId channelId;
  final DateTime? uploadDate;
  final String? uploadDateRaw;
  final DateTime? publishDate;
  final String description;
  final Duration? duration;
  final ThumbnailSet thumbnails;
  final Iterable<String>? keywords;
  final Engagement engagement;
  final bool isLive;
  RxBool isDownloaded;
  final WatchPage? watchPage;
  final String url;

  ExtendedVideo({
    required this.id,
    required this.title,
    required this.author,
    required this.channelId,
    this.uploadDate,
    this.uploadDateRaw,
    this.publishDate,
    required this.description,
    this.duration,
    required this.thumbnails,
    this.keywords,
    required this.engagement,
    required this.isLive,
    required bool isDownloaded,
    this.watchPage,
    required this.url,
  }) : isDownloaded = isDownloaded.obs;
}
